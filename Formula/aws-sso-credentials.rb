class AwsSsoCredentials < Formula
  desc "AWS credentials_process that automatically prompts for SSO"
  homepage "https://github.com/redoapp/aws-sso-credentials"
  version "0.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0/aws-sso-credentials-0.1.0-aarch64-apple-darwin.tar.gz"
      sha256 "388f9687449772901d6bfbc443b1b7bc07e6ee8346c9e6a9130ba5d3e7a6032a"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0/aws-sso-credentials-0.1.0-x86_64-apple-darwin.tar.gz"
      sha256 "c734edf4dc96d830d2d330c10464732128580fffc4302a66352bb1572d27805d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0/aws-sso-credentials-0.1.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "521b70b1d3ea07c39d67541091d35b5cec23be548cfa5d208dd054f2569f491f"
    else
      url "https://github.com/redoapp/aws-sso-credentials/releases/download/v0.1.0/aws-sso-credentials-0.1.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "4683c7b28e3ab5fbded087f35f9ae099f4b425322a82bea6e0b88b02fe1ef6ab"
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
