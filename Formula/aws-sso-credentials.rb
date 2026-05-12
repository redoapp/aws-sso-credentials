class AwsSsoCredentials < Formula
  desc "AWS credentials process that automatically prompts SSO"
  homepage "https://github.com/redoapp/aws-sso-credentials"
  version "0.3.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.3.0/aws-sso-credentials-0.3.0-aarch64-apple-darwin.tar.gz"
      sha256 "09e26e40ada6fffa116f2e536efc3e18a18b2ddf85d8bf9a77b8b9d0a922fd5e"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.3.0/aws-sso-credentials-0.3.0-x86_64-apple-darwin.tar.gz"
      sha256 "7223f9dea780af6ec026e88833160bb4f78544d98a58203fb1895baeadfc01b7"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.3.0/aws-sso-credentials-0.3.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "bec39ccbbd7efcee35c08008523b4f602fd5d4b7a6f6868563374628d240b0c5"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.3.0/aws-sso-credentials-0.3.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "5d763d397acb4e6dc2b5c2a282c10a38a1e3c54b212855ee7b9194781cab557b"
    end
  end

  head do
    url "https://github.com/redoapp/aws-sso-credentials.git", branch: "main"
    depends_on "rust" => :build
  end

  def install
    if build.head?
      system "cargo", "install", *std_cargo_args
    else
      bin.install "aws-sso-credentials"
    end
  end

  def caveats
    <<~EOS
      aws-sso-credentials shells out to `aws sso login`. Make sure the AWS CLI
      is installed and on your PATH (e.g. `brew install awscli`).
    EOS
  end

  test do
    assert_predicate bin/"aws-sso-credentials", :executable?
  end
end
