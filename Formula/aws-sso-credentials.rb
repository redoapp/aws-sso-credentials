class AwsSsoCredentials < Formula
  desc "AWS credentials_process that automatically prompts for SSO"
  homepage "https://github.com/redoapp/aws-sso-credentials"
  version "0.2.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.2.0/aws-sso-credentials-0.2.0-aarch64-apple-darwin.tar.gz"
      sha256 "d799d57ecb22497fbd8c66b4df5215c2e5a3cef0a38dd07818c2a5b89d972070"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.2.0/aws-sso-credentials-0.2.0-x86_64-apple-darwin.tar.gz"
      sha256 "14cd5288174c15e8a1b0acda11f1aef870714eb777194758266010f3d68376f0"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.2.0/aws-sso-credentials-0.2.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "6c4d932b85323ab2338434115f810907ad1e3fad95df789c0abf81b0fc8172c6"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.2.0/aws-sso-credentials-0.2.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "b16d0925ae38cc62e6e4806288262521fa4eba07f5a2c02169fbcf27bdd44a7b"
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
