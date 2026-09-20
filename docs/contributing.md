# Contributing to ConfiChat

Thank you for your interest in contributing to **ConfiChat**! We welcome contributions from everyone and are excited to see what you bring to the project. Below are the guidelines for contributing to this Flutter application.

## I. Getting Started

1. **Fork the Repository**
   - Start by forking the ConfiChat repository on GitHub. This creates your own copy of the project where you can make changes.

2. **Clone Your Fork**
   - Clone your forked repository to your local machine.
   ```bash
   git clone https://github.com/your-username/ConfiChat.git
   cd ConfiChat
   ```

3. **Set Upstream Remote**
   - Set the original repository as the upstream remote to easily sync changes.
   ```bash
   git remote add upstream https://github.com/original-owner/ConfiChat.git
   ```

4. **Create a New Branch**
   - Always create a new branch for your work to keep your changes organized and separate from the main codebase.
   ```bash
   git checkout -b your-feature-branch
   ```

## II. Adding a New Language/Localization

1. **Create a New Language File**
   - Create a new language file in the `confichat/assets/i18n` directory by
     copying the en.json file and rename it to the language code (e.g., fr.json for French). 
     Use language code (Set1) from ISO 639: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes


2. **Update the `languages.yaml` and add the language/local you wish to contribute.**
    Endonmyns can be found from ISO 639: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes and country codes from ISO 3166: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2


3. **Add the new language file to the `assets` section of the `pubspec.yaml` file**
   - Add the new language file to the `assets` section of the `pubspec.yaml` file.
   - 
   ```yaml
   assets:
     - assets/i18n/en.json
     - assets/i18n/fr.json
   ```
   

4. **Translate the Strings**
   - Translate the strings in the new language file to the desired language. Make sure to keep the same key names as the English file.
   

5. **Create a Pull Request**
   - Once you have translated the strings, create a pull request to add the new language to the project.

## III. Best Practices

- **Follow Flutter Best Practices**: Ensure your code follows Flutter's [best practices](https://flutter.dev/docs/development/ui/layout/best-practices).
- **Prioritize Privacy and Security**:
  - **Data Encryption**: Ensure that you maintain features on sensitive data, such as chat histories, is encrypted and stored locally.
  - **Secure API Calls**: Use HTTPS for all online API calls and handle API keys securely, avoiding hardcoding them in the codebase. Check out the LlmApi class.
  - **Minimal Data Retention**: Retain only the necessary data and implement clear data deletion mechanisms.
  - **User Permissions**: Request only the necessary permissions from users, and ensure these permissions are handled securely.
  - **Sensitive Data Handling**: Avoid logging sensitive information such as API keys, user credentials, or private conversations.
- **Focus on Memory and Resource Efficiency**: 
  - Use lazy initialization to avoid unnecessary memory usage.
  - Dispose of controllers and listeners properly to free up resources.
  - Prefer `const` constructors where possible to reduce widget rebuilds.
  - Avoid unnecessary object creation inside loops or frequently called methods.
  - Use efficient data structures like `List` or `Set` instead of less efficient ones.
- **Write Clear and Descriptive Commit Messages**: Provide clear and concise commit messages to describe your changes.
- **Keep Commits Small and Focused**: Break down large changes into smaller, focused commits for easier review.
- **Test Your Changes**: Make sure your changes don’t break any existing functionality. Write tests if applicable.

### AI-assisted contributions

You may use AI tools to help write code, tests, or documentation. A human contributor must review the resulting changes, understand how they work, and take responsibility for what they submit.

- Check generated code against the project’s behavior, style, privacy, and security requirements. Remove code you cannot explain or verify.
- Run the relevant tests and describe any checks you could not perform. Review diffs for secrets, private data, and unrelated changes before opening a pull request.
- In the pull request description, say if AI tools materially helped create the change and briefly explain which parts they helped with. This is context for reviewers, not a substitute for your own review.
- A human maintainer reviews and decides whether to merge each pull request. Passing CI or receiving an AI review does not replace that decision.

### License for contributions

ConfiChat is licensed under the [Apache License 2.0](../LICENSE). Under Section 5, contributions intentionally submitted for inclusion are submitted under that license unless you explicitly state otherwise. We can only merge contributions that we have the right to distribute under Apache 2.0.

By opening a pull request, please confirm that you have the right to submit all of its code, tests, documentation, and assets under Apache 2.0. This includes permission from an employer or other copyright owner when needed. Do not include third-party material with incompatible terms or material copied from a source whose license you cannot verify. If any part needs different terms or attribution, describe it in the pull request before it is merged.

## IV. Submitting a Pull Request

1. **Push Your Changes**
   - Once you’re happy with your changes, push your branch to your forked repository.
   ```bash
   git push origin your-feature-branch
   ```

2. **Create a Pull Request**
   - Go to the original ConfiChat repository on GitHub and create a pull request from your branch. Describe your changes in detail and mention any related issues.

3. **CI Checks**
   - GitHub CI is enabled to automatically check pull requests. This includes tests and linting to ensure code quality. Please review any feedback from CI and make necessary adjustments.

4. **Code Review**
   - Your pull request will be reviewed by the maintainers. Be open to feedback and make any requested changes.

5. **Merge**
   - Once approved, your pull request will be merged into the main codebase.

## V. Keeping Your Fork Updated

To keep your fork up to date with the latest changes from the original repository:

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

## VI. Need Help?

If you have any questions or need help, feel free to open an issue on GitHub or reach out to the community.

Happy coding! 🚀
