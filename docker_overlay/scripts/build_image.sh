#!/bin/bash


# Set to exit on error
set -Ee

## Check if a sudo password should be cached
#sudo -K
#sudo -n ls || read -s -p "Enter sudo password for $(whoami): " passwd
## TODO: Validate password

# Should be date in format 22-08-2021-timestamp so it looks like 220821-1629
start=$(date +%d%m%y-%H%M%S)

BASE_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_dir=${BUILD_DIR:-"${BASE_DIR}/build"}
output_dir=${OUTPUT_DIR:-"${BASE_DIR}/outputs"}
echo "build_dir=${build_dir}"
echo "output_dir=${output_dir}"

export CORE_REF=${CORE_REF:-"dev"}

image_build_type="mark2"
if [ ${BUILD_TYPE} ]; then
  image_build_type=${BUILD_TYPE}
fi

echo "Starting Image Build For ${image_build_type}"

if [ ! -d "${build_dir}" ]; then
    echo "Creating 'build' directory"
    mkdir -p "${build_dir}"
fi
cd "${build_dir}" || exit 10

if [ ! -f Manjaro-ARM-minimal-rpi4-22.08.img.gz ]; then
    echo "Downloading Base Image"
    wget http://downloads.openvoiceos.com/Manjaro-ARM-minimal-rpi4-22.08.img.gz
fi

gzip --decompress Manjaro-ARM-minimal-rpi4-22.08.img.gz -v --keep && echo "Decompressed Image"

# Get Build info
cd "${BASE_DIR}" || exit 10
echo "Got Build Info"

# Cache sudo password for setup
#echo "${passwd}" | sudo -S ls
echo "Running Prepare"
bash /scripts/prepare.sh "${build_dir}/Manjaro-ARM-minimal-rpi4-22.08.img" "${build_dir}" -y "${image_build_type}"

# Cache sudo password for cleanup
#echo "${passwd}" | sudo -S ls
echo "Running Cleanup"
bash /scripts/cleanup.sh "${build_dir}"

if [ ! -d "${output_dir}" ]; then
    echo "Creating 'output' directory"
    mkdir "${output_dir}"
fi

# Rename completed image file
filename="ovos-dev-edition-${image_build_type}-${start}.img"
echo "Writing output file to: ${build_dir}/${filename}"
mv "${build_dir}/Manjaro-ARM-minimal-rpi4-22.08.img" "${build_dir}/${filename}"

# Compress image and move to output directory
echo "Compressing output file. This may take an hour or two..."
compress_start=$(date +%s)
xz --compress -T0 "${build_dir}/${filename}" -v
compress_time=$(($(($(date +%s)-compress_start))/60))
echo "Image compressed in ${compress_time} minutes"
mv "${build_dir}/${filename}.xz" "${output_dir}/${filename}.xz"
echo "Image saved to ${output_dir}/${filename}.xz"
runtime=$(($(($(date +%s)-start))/60))
echo "Image created in ${runtime} minutes"
