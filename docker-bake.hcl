group "default" {
    targets = ["download", "auto"]
}

target "download" {
    context = "./services/download"
    dockerfile = "Dockerfile"
    tags = ["ghcr.io/chemputer/download:latest"]
    push = true
    platforms = ["linux/amd64"]
    volumes = ["./data:/data"]
}

target "auto" {
    context = "./services/AUTOMATIC1111"
    dockerfile = "Dockerfile"
    tags = ["ghcr.io/chemputer/auto:latest"]
    push = true
    platforms = ["linux/amd64"]
    args = {
        CLI_ARGS = "--allow-code --medvram --xformers --enable-insecure-extension-access --api"
    }
    labels = {
        service = "sd-auto:78"
    }
    ports = ["7860:7860"]
    volumes = ["./data:/data", "./output:/output"]
    stop_signal = "SIGKILL"
    tty = true
    capabilities = {
        nvidia = "compute,utility"
    }
}
