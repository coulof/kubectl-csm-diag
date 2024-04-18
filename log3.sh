#!/bin/bash

# Prompt user to select CSI driver
echo "Select the CSI driver for which you want to collect logs:"
echo "1) PowerFlex"
echo "2) PowerMax"
echo "3) PowerScale"
echo "4) PowerStore"
echo "5) Unity"
read -p "Enter your choice (1-5): " csiChoice

# Set the csiDriver variable based on user choice
case $csiChoice in
    1) csiDriver=("vxflexos" "powerflex")
       ;;
    2) csiDriver=("powermax")
       ;;
    3) csiDriver=("powerscale")  # Assuming 'powerscale' is the correct identifier; adjust if necessary
       ;;
    4) csiDriver=("powerstore")
       ;;
    5) csiDriver=("unity")
       ;;
    *) echo "Invalid choice. Exiting."
       exit 1
       ;;
esac

# Function to check if zip is installed and install it if it's not
check_zip() {
    if ! command -v zip &> /dev/null; then
        echo "zip could not be found. Attempting to install zip using yum..."
        sudo yum install zip -y
    fi
}

# Define directory and file names
baseDir="Dell-CSI-Logs"
outputFile="${baseDir}/Node-Information.txt"
zipFile="${baseDir}.zip"
errorsFile="common_errors.txt"
matchesFile="${baseDir}/error_matches.txt"

# Check if zip is installed
check_zip

# Create base directory for logs
mkdir -p "$baseDir"

# Collect node information
echo "Nodes Information:" > "$outputFile"
nodes=$(kubectl get nodes --selector='!node-role.kubernetes.io/master' -o jsonpath='{.items[*].metadata.name}')
for node in $nodes; do
    labelFound=false
    for driver in "${csiDriver[@]}"; do
        labels=$(kubectl get node "$node" -o jsonpath="{.metadata.labels}")
        matches=$(echo "$labels" | grep -o "${driver}[^ ,]*" | sed 's/^/    - /')
        if [ ! -z "$matches" ]; then
            echo "- Name: $node" >> "$outputFile"
            echo "  Labels containing '${driver}':" >> "$outputFile"
            echo "$matches" >> "$outputFile"
            echo "" >> "$outputFile"  # Add a blank line for readability
            labelFound=true
            break  # Stop checking if a label is found
        fi
    done
    if [ "$labelFound" = false ]; then
        echo "- Name: $node" >> "$outputFile"
        echo "  Labels containing CSI driver: None" >> "$outputFile"
        echo "" >> "$outputFile"
    fi
done

# CSINodes section
echo "CSINodes Information:" >> "$outputFile"
kubectl get csinode -o yaml >> "$outputFile"

# Ask for the namespace
echo -n "Enter the namespace where the CSI driver is deployed:"
read -r namespace

# Ask how the CSI was deployed
echo "Was the CSI deployed using the CSM Operator or Helm?"
echo "1) CSM Operator"
echo "2) Helm"
read -p "Enter your choice (1-2): " deploymentMethod

if [ "$deploymentMethod" == "1" ]; then
    # Fetch CSI driver's Custom Resource if CSM Operator was used
    if [ "$csiDriver" == "vxflexos" ] || [ "$csiDriver" == "powerflex" ]; then
        echo "Fetching CSI driver's Custom Resource..."
        kubectl get csm/$csiDriver -n "$namespace" -o yaml > "${baseDir}/CR.yaml"
        echo "CSI driver's Custom Resource has been stored in ${baseDir}/CR.yaml"
    fi
elif [ "$deploymentMethod" == "2" ]; then
    # Fetch Helm values if Helm was used
    helmReleaseName=$(helm ls -n "$namespace" --short | grep -E "(vxflexos|powerflex)")
    if [ ! -z "$helmReleaseName" ]; then
        echo "Fetching Helm values for $helmReleaseName..."
        helm get values "$helmReleaseName" -n "$namespace" > "${baseDir}/VALUES.yaml"
        echo "Helm values for $helmReleaseName have been stored in ${baseDir}/VALUES.yaml"
    else
        echo "No Helm release found for CSI driver in namespace $namespace."
    fi
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Display pods in the provided namespace
echo "Listing all pods in namespace '$namespace':" >> "$outputFile"
kubectl get pods -n "$namespace" >> "$outputFile"
echo "" >> "$outputFile"

# Process CSI driver specific pods
echo "Processing CSI driver pods in namespace '$namespace'..." >> "$outputFile"
for driver in "${csiDriver[@]}"; do
    driverPods=$(kubectl get pods -n "$namespace" -o jsonpath="{.items[*].metadata.name}" | tr " " "\n" | grep "^${driver}")
    if [ -z "$driverPods" ]; then
        echo "No '${driver}' pods found in the namespace $namespace." >> "$outputFile"
    else
        for podName in $driverPods; do
            podDir="${baseDir}/${namespace}_${podName}"
            mkdir -p "$podDir"
            containers=$(kubectl get pod "$podName" -n "$namespace" -o jsonpath='{.spec.containers[*].name}')
            for container in $containers; do
                echo "Fetching logs for container: $container in pod: $podName"
                kubectl logs "$podName" -c "$container" -n "$namespace" > "${podDir}/${container}_logs.txt"
                echo "Logs for container $container in pod $podName have been saved to ${podDir}/${container}_logs.txt"
            done
        done
    fi
done

echo "Log collection complete."

# Prompt for zipping the logs
read -p "Would you like to zip the contents of the Dell-CSI-Logs directory? (y/n): " zipResponse
if [[ "$zipResponse" =~ ^[Yy]$ ]]; then
    echo "Zipping the Dell-CSI-Logs directory..."
    zip -r "$zipFile" "$baseDir"
    echo "Dell-CSI-Logs directory has been zipped into $zipFile"
else
    echo "Skipping zipping the Dell-CSI-Logs directory."
fi
