#!/bin/bash

# ---------------------------
# Colors
# ---------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# ---------------------------
# Logging
# ---------------------------
LOG_FILE="setup-log-$(date +%Y%m%d-%H%M%S).txt"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE} One-Click Dev Environment Setup${NC}"
echo -e "${BLUE}Log file: $LOG_FILE${NC}"
echo -e "${BLUE}=====================================${NC}"

# ---------------------------
# Progress Bar Function
# ---------------------------
progress_bar() {
    local duration=$1
    local msg=$2
    echo -ne "${YELLOW}$msg ${NC}"
    for ((i=0; i<20; i++)); do
        echo -ne "▮"
        sleep $(bc -l <<< "$duration/20")
    done
    echo -e " ${GREEN}Done!${NC}"
}

# ---------------------------
# Helper for installation with progress
# ---------------------------
install_tool() {
    TOOL_NAME=$1
    CMD_CHECK=$2
    INSTALL_CMD=$3
    ESTIMATED_TIME=$4

    echo -e "${BLUE}Installing $TOOL_NAME...${NC}"
    if ! command -v $CMD_CHECK &> /dev/null; then
        progress_bar $ESTIMATED_TIME "Installing $TOOL_NAME..."
        eval $INSTALL_CMD
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}$TOOL_NAME installed successfully!${NC}"
        else
            echo -e "${RED}Failed to install $TOOL_NAME.${NC}"
        fi
    else
        echo -e "${GREEN}$TOOL_NAME is already installed.${NC}"
    fi
}

# ---------------------------
# OS Detection
# ---------------------------
OS="$(uname -s)"
echo -e "${YELLOW}Detected OS: $OS${NC}"

# ---------------------------
# macOS / Linux / WSL Setup
# ---------------------------
if [[ "$OS" == "Darwin" ]]; then
    echo -e "${YELLOW}Running macOS setup...${NC}"

    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo -e "${YELLOW}Updating Homebrew...${NC}"
    brew update

    echo -e "${YELLOW}Installing tools from Brewfile...${NC}"
    brew bundle --file ./Brewfile

elif [[ "$OS" == "Linux" ]]; then
    echo -e "${YELLOW}Running Linux / WSL setup...${NC}"

    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew (Linux)...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Load brew environment (Linux only)
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    echo -e "${YELLOW}Updating Homebrew...${NC}"
    brew update

    echo -e "${YELLOW}Installing tools from Brewfile (no cask)...${NC}"
    brew bundle --file ./Brewfile --no-cask
fi


# Setup NVM environment (works for both macOS and Linux if installed via Brewfile)
if command -v nvm &> /dev/null || [ -d "$(brew --prefix nvm 2>/dev/null)" ]; then
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"

    if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
        source "$(brew --prefix nvm)/nvm.sh"
    fi

    if ! command -v node &> /dev/null; then
        progress_bar 5 "Installing Node.js LTS..."
        nvm install --lts
    fi
fi

: <<'COMMENT'
# ---------------------------
# macOS Setup
# ---------------------------
if [[ "$OS" == "Darwin" ]]; then
    echo -e "${YELLOW}Running macOS setup...${NC}"
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update

    install_tool "Git" git "brew install git" 2
    install_tool "Docker" docker "brew install --cask docker" 3
    install_tool "Terraform" terraform "brew tap hashicorp/tap && brew install hashicorp/tap/terraform" 2
    install_tool "Python3" python3 "brew install python@3.11" 2
    install_tool "Kubectl" kubectl "brew install kubectl" 2
    install_tool "Helm" helm "brew install helm" 2
    install_tool "AWS CLI" aws "brew install awscli" 2

    if ! command -v nvm &> /dev/null; then
        brew install nvm
        mkdir -p ~/.nvm
        export NVM_DIR="$HOME/.nvm"
        source "$(brew --prefix nvm)/nvm.sh"
        progress_bar 5 "Installing Node.js LTS..."
        nvm install --lts
    fi

# UPDATED PORTION
if [[ "$OS" == "Darwin" ]]; then
    echo -e "${YELLOW}Running macOS setup...${NC}"

    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo -e "${YELLOW}Updating Homebrew...${NC}"
    brew update

    echo -e "${YELLOW}Installing tools from Brewfile...${NC}"
    brew bundle --file ./Brewfile

    # Setup NVM environment (if installed via Brewfile)
    if command -v nvm &> /dev/null || [ -d "$(brew --prefix nvm 2>/dev/null)" ]; then
        export NVM_DIR="$HOME/.nvm"
        mkdir -p "$NVM_DIR"

        if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
            source "$(brew --prefix nvm)/nvm.sh"
        fi

        if ! command -v node &> /dev/null; then
            progress_bar 5 "Installing Node.js LTS..."
            nvm install --lts
        fi
    fi

# ---------------------------
# Linux / WSL Setup
# ---------------------------
elif [[ "$OS" == "Linux" ]]; then
    echo -e "${YELLOW}Running Linux / WSL setup...${NC}"
    sudo apt update && sudo apt upgrade -y

    install_tool "Git" git "sudo apt install -y git" 2
    install_tool "Curl" curl "sudo apt install -y curl" 1
    install_tool "Wget" wget "sudo apt install -y wget" 1
    install_tool "Python3" python3 "sudo apt install -y python3 python3-pip python3-venv build-essential" 2

    echo -e "${BLUE}Installing Docker...${NC}"
    progress_bar 5 "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}Docker installed!${NC}"

    install_tool "Terraform" terraform "wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip && unzip terraform_1.7.5_linux_amd64.zip && sudo mv terraform /usr/local/bin/ && rm terraform_1.7.5_linux_amd64.zip" 2

    echo -e "${BLUE}Installing Node.js LTS via NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    progress_bar 5 "Installing Node.js LTS..."
    nvm install --lts

    install_tool "Kubectl" kubectl "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && chmod +x kubectl && sudo mv kubectl /usr/local/bin/" 2
    install_tool "Helm" helm "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash" 2
    install_tool "AWS CLI" aws "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o aws.zip && unzip aws.zip && sudo ./aws/install && rm -rf aws aws.zip" 2
else
    echo -e "${RED}Unsupported OS: $OS${NC}"
    exit 1
fi
COMMENT

# ---------------------------
# Verification
# ---------------------------
echo -e "${YELLOW}Running Verification...${NC}"
commands=("git" "docker" "aws" "terraform" "node" "python3" "kubectl" "helm")

for cmd in "${commands[@]}"; do
    echo -e "${BLUE}Checking $cmd...${NC}"
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}$cmd is installed at: $(which $cmd)${NC}"
        $cmd --version
    else
        echo -e "${RED}❌ $cmd is NOT installed.${NC}"
    fi
done

echo -e "${GREEN}====================================="
echo -e " Setup Complete! Log saved to $LOG_FILE"
echo -e "=====================================${NC}"
