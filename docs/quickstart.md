# Quick Start Guide

Get up and running with **ConfiChat** by following this guide. Whether you're using local models with Ollama, integrating with OpenAI, or both, this guide will help you get started quickly.

## Table of Contents

1. [Getting started with Local Models](#using-local-models)
   - [1. Install Ollama](#1-install-ollama)
   - [2. Download a Model](#2-download-a-model)
   - [3. Set Up ConfiChat](#3-set-up-confichat)
   - [Additional Resources](#additional-resources)
2. [Getting started with Online Models](#using-online-models)
   - [1. Get Your OpenAI API Key](#1-get-your-openai-api-key)
   - [2. Set Up ConfiChat](#2-set-up-confichat)
   - [3. Configure ConfiChat with Your API Key](#3-configure-confichat-with-your-api-key)
   - [Additional Resources](#additional-resources-1)
3. [Getting started with Both Local and Online Models](#using-both-local-and-online-models)
   - [1. Install Ollama](#1-install-ollama)
   - [2. Download a Model](#2-download-a-model)
   - [3. Set Up ConfiChat](#3-set-up-confichat)
   - [4. Get Your OpenAI API Key](#4-get-your-openai-api-key)
   - [5. Configure ConfiChat with Your API Key](#5-configure-confichat-with-your-api-key)
   - [Additional Resources](#additional-resources-2)
4. [Using ConfiChat with LlamaCpp](#using-confichat-with-llamacpp)
   - [1. Install LlamaCpp](#1-install-llamacpp)
   - [2. Run LlamaCpp Server](#2-run-llamacpp-server)
   - [3. Set Up ConfiChat](#3-set-up-confichat)
   - [Additional Resources](#additional-resources-3)

---

## Using Local Models

Get up and running with **Ollama** and **ConfiChat** in just a few steps. Follow this guide to install Ollama, download a model, and set up ConfiChat.

### 1. Install Ollama

First, install Ollama on your system:

- **macOS**:
  ```bash
  brew install ollama
  ```

- **Windows**:
  Download the installer from the [Ollama website](https://ollama.com) and follow the on-screen instructions.

- **Linux**:
  ```bash
  sudo apt-get install ollama
  ```

For more detailed instructions, refer to the [Ollama installation guide](https://ollama.com/docs/install).

### 2. Download a Model

Once Ollama is installed, you can download the Llama 3.1 model by running:

```bash
ollama pull llama3.1
```

This command will download the Llama 3.1 model to your local machine.

### 3. Set Up ConfiChat

Next, download and set up the ConfiChat interface:

- Clone the ConfiChat repository:
  ```bash
  git clone https://github.com/your-repository/ConfiChat.git
  cd ConfiChat
  ```

- Install dependencies:
  ```bash
  flutter pub get
  ```

- Run the application:
  ```bash
  flutter run
  ```

Now, you're ready to start using ConfiChat with your local Llama 3.1 model!

### Additional Resources

For more detailed instructions and troubleshooting, please visit the [Ollama documentation](https://ollama.com/docs) and the [ConfiChat repository](https://github.com/your-repository/ConfiChat).

---

## Using Online Models

Get started with **ConfiChat** and **OpenAI** by following these simple steps. You'll set up your OpenAI API key, download ConfiChat, and configure it to use OpenAI.

### 1. Get Your OpenAI API Key

To use OpenAI with ConfiChat, you first need to obtain an API key:

1. Go to the [OpenAI API](https://platform.openai.com/account/api-keys) page.
2. Log in with your OpenAI account.
3. Click on "Create new secret key" and copy the generated API key.

Keep your API key secure and do not share it publicly.

### 2. Set Up ConfiChat

Next, download and set up the ConfiChat interface:

- Clone the ConfiChat repository:
  ```bash
  git clone https://github.com/your-repository/ConfiChat.git
  cd ConfiChat
  ```

- Install dependencies:
  ```bash
  flutter pub get
  ```

- Run the application:
  ```bash
  flutter run
  ```

### 3. Configure ConfiChat with Your API Key

Once ConfiChat is running:

1. Navigate to **Settings > OpenAI**.
2. Paste your OpenAI API key into the provided form.
3. Click "Save" to apply the changes.

ConfiChat is now configured to use OpenAI for its language model capabilities!

### Additional Resources

For more detailed instructions and troubleshooting, please visit the [OpenAI documentation](https://platform.openai.com/docs) and the [ConfiChat repository](https://github.com/your-repository/ConfiChat).

---

## Using Both Local and Online Models

Combine the power of local models with the flexibility of online models by setting up both Ollama and OpenAI in ConfiChat.

### 1. Install Ollama

Follow the instructions in the [Install Ollama](#1-install-ollama) section above.

### 2. Download a Model

Follow the instructions in the [Download a Model](#2-download-a-model) section above to download the Llama 3.1 model.

### 3. Set Up ConfiChat

Follow the instructions in the [Set Up ConfiChat](#3-set-up-confichat) section above.

### 4. Get Your OpenAI API Key

Follow the instructions in the [Get Your OpenAI API Key](#1-get-your-openai-api-key) section above.

### 5. Configure ConfiChat with Your API Key

Follow the instructions in the [Configure ConfiChat with Your API Key](#3-configure-confichat-with-your-api-key) section above.

### Additional Resources

For more detailed instructions and troubleshooting, please visit the [Ollama documentation](https://ollama.com/docs), the [OpenAI documentation](https://platform.openai.com/docs), and the [ConfiChat repository](https://github.com/your-repository/ConfiChat).


## Using ConfiChat with LlamaCp

Set up **LlamaCpp** with **ConfiChat** by following these steps. This section will guide you through installing LlamaCpp, running the server, and configuring ConfiChat.

### 1. Install LlamaCpp

To use LlamaCpp, you first need to install it:

- **macOS**:
  ```bash
  brew install llamacpp
  ```

- **Windows**:
  Download the binaries from the [LlamaCpp GitHub releases page](https://github.com/ggerganov/llama.cpp/releases) and follow the installation instructions.

- **Linux**:
  ```bash
  sudo apt-get install llamacpp
  ```

### 2. Run LlamaCpp Server
After installing LlamaCpp, you'll need to run the LlamaCpp server with your desired model:
```
llama-server -m /path/to/your/model --port 8080
```

This command will start the LlamaCpp server, which ConfiChat can connect to for processing language model queries.

### 3. Set Up ConfiChat

Follow the instructions in the [Set Up ConfiChat](#3-set-up-confichat) section above.

### Additional Resources

For more detailed instructions and troubleshooting, please visit the [LlamaCpp documentation](https://github.com/ggerganov/llama.cpp) and the [ConfiChat repository](https://github.com/your-repository/ConfiChat).
