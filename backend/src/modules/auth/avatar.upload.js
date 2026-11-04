const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const sharp = require('sharp');

const uploadDir = path.join(__dirname, '../../../uploads');
fs.mkdirSync(uploadDir, { recursive: true });

module.exports = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    const extension = path.extname(file.originalname).toLowerCase();
    const imageExtension = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(extension);
    if (!file.mimetype.startsWith('image/') && !imageExtension) {
      callback(new Error('Profile picture must be an image'));
      return;
    }
    callback(null, true);
  },
});

async function saveAsWebp(file) {
  const filename = `${Date.now()}-${crypto.randomUUID()}.webp`;
  await sharp(file.buffer)
    .webp({ quality: 82 })
    .toFile(path.join(uploadDir, filename));
  return filename;
}

module.exports.saveAsWebp = saveAsWebp;
