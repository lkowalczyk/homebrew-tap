class ProtobufAT241 < Formula
  desc "Protocol buffers (Google's data interchange format)"
  homepage "https://github.com/google/protobuf"
  url "https://github.com/google/protobuf/releases/download/v2.4.1/protobuf-2.4.1.tar.bz2"
  sha256 "cf8452347330834bbf9c65c2e68b5562ba10c95fa40d4f7ec0d2cb332674b0bf"

  keg_only :versioned_formula

  # this will double the build time approximately if enabled
  option "with-test", "Run build-time check"
  option :cxx11

  depends_on :python => :optional

  deprecated_option "with-check" => "with-test"

  patch :p0 do
    url "clang.patch"
    sha256 "6e4a6cd6ffe33bb594d235c15fa9309df2c0783df418a418a00edcc640978c4d"
  end

  def install
    # Don't build in debug mode. See:
    # https://github.com/Homebrew/homebrew/issues/9279
    ENV.prepend "CXXFLAGS", "-DNDEBUG"
    ENV.cxx11 if build.cxx11?

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-zlib"
    system "make"
    system "make", "check" if build.with?("test") || build.bottle?
    system "make", "install"

    # Install editor support and examples
    doc.install "editors", "examples"

    if build.with? "python"
      chdir "python" do
        ENV["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "cpp"
        ENV.append_to_cflags "-I#{include}"
        ENV.append_to_cflags "-L#{lib}"
        args = Language::Python.setup_install_args libexec
        system "python", *args
      end
      site_packages = "lib/python2.7/site-packages"
      pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
      (prefix/site_packages/"homebrew-protobuf.pth").write pth_contents
    end
  end

  def caveats; <<~EOS
    Editor support and examples have been installed to:
      #{doc}
    EOS
  end

  test do
    (testpath/"test.proto").write <<~EOS
      package test;
      message TestCase {
        required string name = 4;
      }
      message Test {
        repeated TestCase case = 1;
      }
    EOS
    system bin/"protoc", "test.proto", "--cpp_out=."
    if build.with? "python"
      protobuf_pth = lib/"python2.7/site-packages/homebrew-protobuf.pth"
      (testpath.realpath/"Library/Python/2.7/lib/python/site-packages").install_symlink protobuf_pth
      system "python", "-c", "import google.protobuf"
    end
  end
end
