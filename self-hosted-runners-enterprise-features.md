# Configure Self-hosted Runners for Enterprise

There are **`additional features`** and configuration options when using GitHub Enterprises Self-hosted runners.

These are:

For self-hosted runners in GitHub Actions, the documented extra network configuration options are:

1. Proxy servers

   - Configure `https_proxy`, `http_proxy`, and `no_proxy` as environment variables.
   - Set them before starting the runner application.
   - If the proxy changes, restart the runner application.
   - On Windows, you can also use netsh.
   - On self-hosted runners, you can also put proxy variables in a .env file in the runner application directory.
   - See Using proxy servers with a runner.

   Example of configuring these options:

   ```bash
   export https_proxy=http://proxy.local:8080
   export http_proxy=http://proxy.local:8080
   export no_proxy=example.com,localhost,127.0.0.1
   ```

   For a self-hosted runner, you can also put proxy settings in a `.env` file in the runner application directory:

   ```bash
   https_proxy=http://proxy.local:8080
   no_proxy=example.com,myserver.local:443
   ```

2. IP allow lists

   - You must add the IP address or range of your self-hosted runners to the IP allow list for communication to work
