// Generates the two tiny independent DNG fixtures in this directory.
// Build against TinyDNG commit 5e5686e468738ada1b4edc5b334c1fe548f91a8d.
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

#define TINY_DNG_WRITER_IMPLEMENTATION
#include "tiny_dng_writer.h"

static bool write_fixture(const char *path, bool big_endian, bool compressed) {
  const unsigned width = 8;
  const unsigned height = 6;
  std::vector<uint16_t> pixels(width * height);
  for (unsigned y = 0; y < height; ++y) {
    for (unsigned x = 0; x < width; ++x) {
      pixels[y * width + x] = static_cast<uint16_t>(512 + y * 1000 + x * 73);
    }
  }

  tinydngwriter::DNGImage image;
  image.SetBigEndian(big_endian);
  image.SetSubfileType(false, false, false);
  image.SetOrientation(tinydngwriter::ORIENTATION_TOPLEFT);
  const unsigned stored_width = compressed ? width * 2 : width;
  const unsigned stored_height = compressed ? height / 2 : height;
  image.SetImageWidth(stored_width);
  image.SetImageLength(stored_height);
  image.SetRowsPerStrip(stored_height);
  image.SetSamplesPerPixel(1);
  // TinyDNG 5e5686e double-swaps this inline SHORT in big-endian mode.
  const uint16_t bits = big_endian ? 0x1000 : 16;
  image.SetBitsPerSample(1, &bits);
  image.SetPhotometric(tinydngwriter::PHOTOMETRIC_CFA);
  image.SetPlanarConfig(tinydngwriter::PLANARCONFIG_CONTIG);
  image.SetCompression(compressed ? tinydngwriter::COMPRESSION_NEW_JPEG
                                  : tinydngwriter::COMPRESSION_NONE);
  image.SetDNGVersion(1, 4, 0, 0);
  image.SetCFARepeatPatternDim(2, 2);
  const unsigned char cfa_little[4] = {0, 1, 1, 2};
  const unsigned char cfa_big[4] = {2, 1, 1, 0};
  image.SetCFAPattern(4, big_endian ? cfa_big : cfa_little);
  const unsigned short black = 512;
  image.SetBlackLevel(1, &black);
  const double white = 15000;
  image.SetWhiteLevelRational(1, &white);
  const double neutral[3] = {0.5, 1.0, 0.7};
  image.SetAsShotNeutral(3, neutral);
  image.SetCalibrationIlluminant1(23);
  std::vector<unsigned char> packed;
  if (!compressed) {
    packed.resize(pixels.size() * 2);
    for (size_t index = 0; index < pixels.size(); ++index) {
      packed[index * 2] = static_cast<unsigned char>(pixels[index] >> 8);
      packed[index * 2 + 1] = static_cast<unsigned char>(pixels[index]);
    }
  }
  const bool data_ok = compressed
      ? image.SetImageDataJpeg(pixels.data(), width, height, 16)
      : image.SetImageData(packed.data(), packed.size());
  if (!data_ok) return false;

  tinydngwriter::DNGWriter writer(big_endian);
  if (!writer.AddImage(&image)) return false;
  std::string error;
  const bool ok = writer.WriteToFile(path, &error);
  if (!error.empty()) std::cerr << error;
  return ok;
}

int main(int argc, char **argv) {
  if (argc != 3) return 2;
  if (!write_fixture(argv[1], true, false)) return 1;
  if (!write_fixture(argv[2], false, true)) return 1;
  return 0;
}
