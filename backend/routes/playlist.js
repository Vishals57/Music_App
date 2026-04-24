const express = require('express');
const router = express.Router();
const Playlist = require('../models/Playlist');
const { authMiddleware } = require('../middleware/auth');

// Create playlist
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { name, description } = req.body;

    const playlist = new Playlist({
      name,
      description,
      userId: req.userId
    });

    await playlist.save();
    res.status(201).json(playlist);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user playlists
router.get('/', authMiddleware, async (req, res) => {
  try {
    const playlists = await Playlist.find({ userId: req.userId })
      .populate('tracks');

    res.json(playlists);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add track to playlist
router.post('/:id/add-track', authMiddleware, async (req, res) => {
  try {
    const { trackId } = req.body;
    const playlist = await Playlist.findById(req.params.id);

    if (!playlist) {
      return res.status(404).json({ error: 'Playlist not found' });
    }

    if (playlist.userId.toString() !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (!playlist.tracks.includes(trackId)) {
      playlist.tracks.push(trackId);
      await playlist.save();
    }

    res.json(playlist);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
