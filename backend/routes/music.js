const express = require('express');
const router = express.Router();
const Track = require('../models/Track');
const { authMiddleware } = require('../middleware/auth');
const { searchYouTube, searchSoundCloud } = require('../services/musicService');

// Search music from YouTube & SoundCloud
router.get('/search', async (req, res) => {
  try {
    const { query, source } = req.query;

    if (!query) {
      return res.status(400).json({ error: 'Query parameter required' });
    }

    let results = [];

    if (source === 'youtube' || !source) {
      const youtubeResults = await searchYouTube(query);
      results = [...results, ...youtubeResults];
    }

    if (source === 'soundcloud' || !source) {
      const soundcloudResults = await searchSoundCloud(query);
      results = [...results, ...soundcloudResults];
    }

    res.json({ results, total: results.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get new releases
router.get('/new-releases', async (req, res) => {
  try {
    const releases = await Track.find()
      .sort({ releaseDate: -1 })
      .limit(50);

    res.json(releases);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get trending tracks
router.get('/trending', async (req, res) => {
  try {
    const trending = await Track.find()
      .sort({ views: -1 })
      .limit(20);

    res.json(trending);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get track by ID
router.get('/:id', async (req, res) => {
  try {
    const track = await Track.findById(req.params.id);
    if (!track) {
      return res.status(404).json({ error: 'Track not found' });
    }

    res.json(track);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add to favorites (protected route)
router.post('/:id/favorite', authMiddleware, async (req, res) => {
  try {
    const User = require('../models/User');
    const user = await User.findById(req.userId);
    
    if (!user.favorites.includes(req.params.id)) {
      user.favorites.push(req.params.id);
      await user.save();
    }

    res.json({ message: 'Added to favorites', favorites: user.favorites });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
