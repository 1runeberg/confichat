![ConfiChat Logo](confichat/assets/confichat_logo_text_outline.png)

[![Windows Build](https://github.com/1runeberg/confichat/actions/workflows/windows_build.yml/badge.svg)](https://github.com/1runeberg/confichat/actions/workflows/windows_build.yml) [![Linux Build](https://github.com/1runeberg/confichat/actions/workflows/linux_build.yml/badge.svg)](https://github.com/1runeberg/confichat/actions/workflows/linux_build.yml) [![Android Build](https://github.com/1runeberg/confichat/actions/workflows/android_build.yml/badge.svg)](https://github.com/1runeberg/confichat/actions/workflows/android_build.yml) [![macOS Build](https://github.com/1runeberg/confichat/actions/workflows/macos_build.yml/badge.svg)](https://github.com/1runeberg/confichat/actions/workflows/macos_build.yml) [![iOS Build](https://github.com/1runeberg/confichat/actions/workflows/ios_build.yml/badge.svg)](https://github.com/1runeberg/confichat/actions/workflows/ios_build.yml)

<br/><br/><br/>
<div style="text-align: center;">
  <a href="./docs/confichat.gif" target="_blank">
    <img src="./docs/confichat_thumb.gif" alt="ConfiChat Sizzle Reel" width="800" style="background: url(./docs/confichat_splash.png) center center no-repeat; background-size: cover;" />
  </a>
</div>
<br/><br/>
<p style="color: #555; font-size: 20px;">
  Welcome to <strong>ConfiChat</strong> – a multi-platform, privacy-focused LLM chat interface with optional encryption of chat history and assets.</p>

<p style="color: #555; font-size: 20px;">
  ConfiChat offers the flexibility to operate either <em>fully offline</em> or <em>blend offline-and-online</em> capabilities:</p>

<ul style="color: #555; font-size: 20px;">
  <li><strong>Offline providers</strong> like <a href="https://ollama.com">Ollama</a> and <a href="https://github.com/ggerganov/llama.cpp">LlamaCpp</a> provide privacy by operating on your local machine or network without cloud services.</li>
  <li><strong>Online providers</strong> like <a href="https://openai.com">OpenAI</a> offer cutting-edge models via APIs, which have different privacy policies than their chat services, giving you greater control over your data.</li>
</ul>


<br/>


### 📦 1. Downloads

We provide [pre-built binaries/executables]() for various platforms, making it easy to get started quickly.

**Note for macOS and iOS users**: *Binaries are not provided due to platform restrictions. Please see the [Compiling on your own](docs/compiling.md) section.*

**Note for Windows users**: *You may encounter a SmartScreen warning since the binaries aren't signed. Rest assured they are safely built via GitHub CI when downloaded directly from the [Releases section](https://github.com/1runeberg/confichat/releases). You can also view the [full build logs](https://github.com/1runeberg/confichat/actions/workflows/publish_release.yml). And of course you can [build from source](docs/compiling.md).*

❤️ If you find this app useful, consider sponsoring us in [GitHub Sponsors](https://github.com/sponsors/1runeberg) to help us secure necessary certificates and accounts for future binary distributions.

💼 If your company needs a bespoke version with robust enterprise features, [Contact Us](https://beyondreality.io/contact-us).

<br/>

### 📖 2. Quick Start Guides

Get started quickly with **ConfiChat** by following one of our [quick start guides](docs/quickstart.md)  depending on whether you want to use local models, online models, or both.

<br/>

###  💬 3. About ConfiChat

**ConfiChat** is a lightweight, multi-platform chat interface designed with privacy and flexibility in mind. It supports both local and online providers.

Unlike other solutions that rely on Docker and a suite of heavy tools, ConfiChat is a standalone app that lets you focus on the models themselves rather than maintaining the UI. This makes it an ideal choice for users who prefer a streamlined, efficient interface.

All chat sessions are managed locally by the app as individual JSON files, with optional encryption available for added security. 

Local LLMs are particularly beneficial for applications requiring offline access, low-latency responses, or the handling of sensitive data that must remain on your device. They also provide more customization and privacy for niche tasks, such as journaling or private counseling.

In a nutshell, ConfiChat caters to users who value transparent control over their AI experience.

<br/>

### ✨ 4. Key Features

- **Cross-Platform Compatibility**: Developed in Flutter, ConfiChat runs on Windows, Linux, Android, MacOS, and iOS

- **Local Model Support (Ollama and LlamaCpp)**: [Ollama](https://ollama.com) & [LlamaCpp](https://github.com/ggerganov/llama.cpp) both offer a range of lightweight, open-source local models, such as [Llama by Meta](https://ai.meta.com/llama/), [Gemma by Google](https://ai.google.dev/gemma), and [Llava](https://github.com/haotian-liu/LLaVA) for multimodal/image support. These models are designed to run efficiently even on machines with limited resources. 

- **OpenAI Integration**: Seamlessly integrates with [OpenAI](https://openai.com) to provide advanced language model capabilities using your [own API key](https://platform.openai.com/docs/quickstart). Please note that while the API does not store conversations like ChatGPT does, OpenAI retains input data for abuse monitoring purposes. You can review their latest [data retention and security policies](https://openai.com/enterprise-privacy/). In particular, check the "How does OpenAI handle data retention and monitoring for API usage?" in their FAQ (https://openai.com/enterprise-privacy/).

- **Privacy-Focused**: Privacy is at the core of ConfiChat's development. The app is designed to prioritize user confidentiality, with optional chat history encryption ensuring that your data remains secure. 

- **Lightweight Design**: Optimized for performance with minimal resource usage.

<br/>

### 🛠️ 5. Compiling your own build

For those who prefer to compile ConfiChat themselves, or for macOS and iOS users, we provide detailed instructions in the [Compiling on your own](docs/compiling.md) section. 

<br/>

### 🤝 6. Contributing

We welcome contributions from the community! Whether you're interested in adding new features, fixing bugs, or improving documentation, your help is appreciated. Please see our [Contributing Guide](docs/contributing.md) for more details.

<br/>

### 💖 7. Sponsorship

Your support helps us maintain and improve ConfiChat. Sponsorships are encouraged for the following items:

- **Code Signing Certificates**: To provide trusted binaries.
- **macOS and iOS Signing Accounts**: To distribute signed binaries for macOS.
- **Continuous Feature Development**: Ensuring regular updates and new features.

If you're interested in supporting ConfiChat, please visit our [Sponsorship Page](https://github.com/sponsors/1runeberg) or if your company needs a bespoke version with robust enterprise features, [Contact Us](https://beyondreality.io/contact-us).
