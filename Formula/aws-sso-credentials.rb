class AwsSsoCredentials < Formula
  desc "AWS credentials_process that automatically prompts for SSO"
  homepage "https://github.com/redoapp/aws-sso-credentials"
  version "0.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.0.0/aws-sso-credentials-0.0.0-aarch64-apple-darwin.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.0.0/aws-sso-credentials-0.0.0-x86_64-apple-darwin.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.0.0/aws-sso-credentials-0.0.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.0.0/aws-sso-credentials-0.0.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  head do
    url "https://github.com/redoapp/aws-sso-credentials.git", branch: "main"
    depends_on "rust" => :build
  end

  depends_on "awscli"

  def install
    if build.head?
      system "cargo", "install", *std_cargo_args
    else
      bin.install "aws-sso-credentials"
    end
  end

  test do
    assert_predicate bin/"aws-sso-credentials", :executable?
  end
end
