const mongoose = require('mongoose');

const trackSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  artist: String,
  album: String,
  duration: Number, // in seconds
  source: {
    type: String,
    enum: ['youtube', 'soundcloud', 'local'],
    default: 'youtube'
  },
  sourceId: String, // YouTube video ID or SoundCloud track ID
  thumbnail: String,
  url: String,
  views: {
    type: Number,
    default: 0
  },
  releaseDate: Date,
  genre: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Track', trackSchema);
