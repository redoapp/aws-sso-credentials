class AwsSsoCredentials < Formula
  desc "AWS credentials_process that automatically prompts for SSO"
  homepage "https://github.com/redoapp/aws-sso-credentials"
  version "0.1.0-alpha"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-aarch64-apple-darwin.tar.gz"
      sha256 "4a97ee7ceac92893c94d40ea0ee6956bcccb4eb6175a14375f8564a17213f724"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-x86_64-apple-darwin.tar.gz"
      sha256 "992bc590705eb7be6db60f641b280cbabacfc841432988f2cd14066f48c85e71"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "38942b2f7a3849abdc7c4963f7fc409bc9aba5fc1c8bbb090804fa840fac35f3"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0-alpha/aws-sso-credentials-0.1.0-alpha-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "7e5cc60d15c420277bdcd1a9743dc8a5bbcdf4e59163c4b3b484d49767cb715c"
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
