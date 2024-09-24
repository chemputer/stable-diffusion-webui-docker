# Stage 3: Final Automatic Service (Stable Diffusion WebUI)
FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

RUN apt update && apt install parallel aria2 -y

# Copy the download script
COPY ./services/download /docker

# Ensure the script is executable
#RUN chmod +x /docker/download.sh

# Run the download service (this will only execute once during the image build)
#RUN /docker/download.sh

# Copy and run the clone script to fetch repositories
COPY clone.sh /docker/clone.sh


RUN chmod +x /docker/clone.sh
RUN chmod +x /docker/download_all.sh

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1

# Install necessary system dependencies
RUN --mount=type=cache,target=/var/cache/apt apt-get update && \
    apt-get install -y fonts-dejavu-core rsync git jq moreutils aria2 \
    ffmpeg libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 libcairo2-dev build-essential && \
    apt-get clean

# Copy cloned repositories from the clone stage
WORKDIR /stable-diffusion-webui
#COPY --from=clone-stage /repositories/ /stable-diffusion-webui/repositories/

# Copy downloaded data from the download stage
#COPY --from=download-stage /docker/data /stable-diffusion-webui/data

# Clone the Stable Diffusion WebUI and install Python dependencies
RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git . && \
    git reset --hard v1.9.4 && \
    pip install -r requirements_versions.txt

# Copy additional scripts for the automatic service
COPY ./services/AUTOMATIC1111 /docker

# Install additional Python packages
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install pyngrok xformers==0.0.26.post1 \
    git+https://github.com/TencentARC/GFPGAN.git@8d2447a2d918f8eba5a4a01463fd48e45126a379 \
    git+https://github.com/openai/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 \
    git+https://github.com/mlfoundations/open_clip.git@v2.20.0

# Install performance optimization libraries
RUN apt-get -y install libgoogle-perftools-dev && apt-get clean
ENV LD_PRELOAD=libtcmalloc.so

# Apply necessary configurations and patches
RUN sed -i 's/in_app_dir = .*/in_app_dir = True/g' /opt/conda/lib/python3.10/site-packages/gradio/routes.py && \
    git config --global --add safe.directory '*'

# Expose port for the WebUI service
EXPOSE 7860

# Set up environment variables
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CLI_ARGS=""

# Define the entrypoint for the automatic service
ENTRYPOINT ["/docker/entrypoint.sh"]

# Start the WebUI
CMD ["python", "-u", "webui.py", "--listen", "--port", "7860", "${CLI_ARGS}"]
