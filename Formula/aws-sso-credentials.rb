class AwsSsoCredentials < Formula
  desc "AWS credentials_process that automatically prompts for SSO"
  homepage "https://github.com/redoapp/aws-sso-credentials"
  version "0.1.0-alpha"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-aarch64-apple-darwin.tar.gz"
      sha256 "5cf1fc2419734b189fdfcfb80097318417559a4653a38d2928ec9d709ac057c2"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-x86_64-apple-darwin.tar.gz"
      sha256 "fa21c693e1b6175a2769b564b3ed4162b1810073a0f2599ea348845da3e43a40"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "f8dcc93a88ee006d186c5d546ab96831e2f1775f2c93e5e7968e09c7b05a30a7"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "1dd2f59871292540c8fbf49f805c55d325243058748d66f09cc628b4d15b48ed"
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
