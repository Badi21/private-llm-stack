# 🚀 Private LLM Stack

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/badi21/private-llm-stack?style=social)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Docker Pulls](https://img.shields.io/badge/docker%20pulls-compatible-blue)
[![Twitter Follow](https://img.shields.io/twitter/follow/badrmind?style=social)](https://twitter.com/badrmind)

**Deploy your own secure and private conversational AI platform in minutes**

[English](./README_EN.md) | [Español](./README.md)
</div>

## 📋 Contents

- [🔍 Overview](#-overview)
- [✨ Features](#-features)
- [🖥️ System Requirements](#️-system-requirements)
- [📦 Quick Install](#-quick-install)
- [🛠️ Advanced Configuration](#️-advanced-configuration)
- [🤖 Compatible Models](#-compatible-models)
- [🔐 Security](#-security)
- [🔄 Updating](#-updating)
- [❓ FAQ](#-faq)
- [👥 Contributing](#-contributing)
- [📜 License](#-license)

## 🔍 Overview

**Private LLM Stack** allows you to deploy your own **autonomous, private, and secure ChatGPT** on any VPS server, using advanced language models like LLaMA, Mistral, and others. All with a modern ChatGPT-like web interface, protected with HTTPS and authentication.

> **Why use Private LLM Stack?** Keep your sensitive data under your control, avoid external dependencies, and operate completely offline after initial installation.

## ✨ Features

- **🧠 Locally installed AI**: Ollama AI runtime with support for multiple language models
- **🎭 Multiple models based on your hardware**: From lightweight options (2GB RAM) to advanced models (16GB+)
- **🖌️ Modern web interface**: Open WebUI with ChatGPT-like design, mobile compatible
- **🔒 Built-in security**: NGINX as reverse proxy, automatic HTTPS with SSL, and basic authentication
- **🚀 One-step installation**: Automated script that configures the entire stack
- **📱 Cross-platform access**: Access from any device through your secure domain
- **🔄 Compatible API**: Exposes OpenAI-compatible API endpoints for integrations
- **💾 No cloud data**: All information is processed and stored locally
- **🛠️ Easy maintenance**: Simple commands to update and manage the system

## 🖥️ System Requirements

| Resource | Minimum Requirement | Recommended |
|---------|-----------------|-------------|
| CPU | 2 vCPU | 4+ vCPU (AVX2 supported) |
| RAM | 2GB (lightweight models) | 8-16GB (advanced models) |
| Storage | 10GB free | 20GB+ SSD |
| OS | Ubuntu 20.04/22.04 | Ubuntu 22.04+ or Debian 11+ |
| Network | Ports 80, 443 open | Stable upload speed |
| Domain | Required for SSL | With DNS configured to your server |

## 📦 Quick Install

```bash
# 1. Download the installation script
curl -sSL https://raw.githubusercontent.com/badi21/private-llm-stack/main/install.sh -o install.sh

# 2. Make the script executable
chmod +x install.sh

# 3. Run the installer
./install.sh
```

The script will guide you through an interactive process to choose your model, configure your domain, and set access credentials.

## 🛠️ Advanced Configuration

To customize the installation, you can run the script with options:

```bash
./install.sh --model mistral:7b-instruct --domain ai.yourdomain.com --username admin
```

Available parameters:
- `--model`: Select the AI model (see [compatible models](#-compatible-models))
- `--domain`: Specify the domain for web access
- `--username`: Define the username for authentication
- `--port`: Change the default port (default: 3000)
- `--no-ssl`: Skip SSL configuration (not recommended)
- `--help`: Display all available options

## 🤖 Compatible Models

Private LLM Stack is compatible with all Ollama models. We recommend:

| Model | Minimum RAM | Use Case |
|--------|------------|------------|
| phi | 2GB | Basic chatbot, limited resource devices |
| gemma:2b | 4GB | General assistant, good performance/resource ratio |
| tinyllama | 2GB | Lightweight assistant for budget VPS |
| llama2:7b-chat | 8GB | Advanced conversation, better comprehension |
| mistral:7b-instruct | 8GB | Excellent general performance, complex instructions |
| neural-chat | 12-16GB | Premium conversational experience, high accuracy |

> 💡 **Tip**: You can install multiple models and switch between them according to your needs.

## 🔐 Security

- **Automatic HTTPS**: Self-managed Let's Encrypt certificates
- **Authentication**: Protection with username/password
- **Isolation**: Docker for secure containerization
- **Local Communication**: Data never leaves your server

### Security Best Practices

- Change the authentication password regularly
- Update the system and components regularly
- Use a firewall to limit access to the server
- Consider setting up a VPN for more secure remote access


## 🔄 Updating

To update the system to the latest version:

```bash
cd private-llm-stack
git pull
./update.sh
```

## ❓ FAQ

<details>
<summary><b>Is it possible to use this system without an internet connection?</b></summary>
Yes, once installed and the models downloaded, the system can function completely offline.
</details>

<details>
<summary><b>How can I add more users?</b></summary>
You can add more users by editing the NGINX authentication file:

```bash
sudo htpasswd /etc/nginx/.htpasswd new_user
```
</details>

<details>
<summary><b>Does it work on a Raspberry Pi?</b></summary>
Yes, with lightweight models (phi, tinyllama) it can work on a Raspberry Pi 4 with 4GB+ RAM.
</details>

<details>
<summary><b>Can I use this for commercial purposes?</b></summary>
Yes, but you should verify the licenses of the specific models you use, as they vary.
</details>

## 👥 Contributing

Contributions are welcome! If you want to improve Private LLM Stack:

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add: amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

You can also [report issues](https://github.com/badi21/private-llm-stack/issues) or [suggest improvements](https://github.com/badi21/private-llm-stack/discussions).

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
<p>Like this project? Give it a star! ⭐</p>
<p>Created with 💻 by <a href="https://github.com/badi21">Badar - بدر دين | Software Engineer & Inspiration</a></p>
</div>