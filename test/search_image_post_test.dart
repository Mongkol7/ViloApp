import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/search_discover/domain/entities/search_results.dart';
import 'package:viloapp/features/feed/data/models/video_model.dart';

void main() {
  group('Search Multi-Image Post & Relevance Tests', () {
    test('TrendingVideo toVideoModel preserves multiple image URLs and audioUrl', () {
      const tv = TrendingVideo(
        id: '99',
        thumbnailUrl: '/uploads/photos/photo1.jpg',
        views: '0',
        title: 'Angkor Wat Sunrise',
        caption: 'Angkor Wat Sunrise photo carousel',
        authorUsername: '@traveler',
        authorName: 'Traveler',
        mediaUrls: [
          '/uploads/photos/photo1.jpg',
          '/uploads/photos/photo2.jpg',
          '/uploads/photos/photo3.jpg',
        ],
        imageUrls: [
          '/uploads/photos/photo1.jpg',
          '/uploads/photos/photo2.jpg',
          '/uploads/photos/photo3.jpg',
        ],
        audioUrl: '/uploads/music/traditional_flute.mp3',
        soundId: 5,
        musicTitle: 'Traditional Khmer Flute',
        musicArtist: 'Master Artist',
      );

      final VideoModel model = tv.toVideoModel();

      expect(model.id, 99);
      expect(model.isImagePost, isTrue);
      expect(model.isMultiImagePost, isTrue);
      expect(model.resolvedMediaUrls.length, 3);
      expect(model.mediaUrls.length, 3);
      expect(model.imageUrls.length, 3);
      expect(model.audioUrl, '/uploads/music/traditional_flute.mp3');
      expect(model.resolvedAudioUrl, isNotNull);
      expect(model.musicTitle, 'Traditional Khmer Flute');
      expect(model.musicArtist, 'Master Artist');
    });

    test('TrendingVideo toVideoModel parses comma-separated videoUrl if mediaUrls was empty', () {
      const tv = TrendingVideo(
        id: '100',
        thumbnailUrl: '/uploads/photos/imgA.png',
        views: '10',
        title: 'Phnom Penh City Walk',
        caption: 'City walk memories',
        authorUsername: '@city_walker',
        videoUrl: '/uploads/photos/imgA.png,/uploads/photos/imgB.png,/uploads/photos/imgC.png',
        audioUrl: '/uploads/music/city_sound.mp3',
      );

      final VideoModel model = tv.toVideoModel();

      expect(model.isImagePost, isTrue);
      expect(model.isMultiImagePost, isTrue);
      expect(model.resolvedMediaUrls.length, 3);
      expect(model.audioUrl, '/uploads/music/city_sound.mp3');
    });

    test('Exact title search query ranks highest relevance over higher-view non-exact matches', () {
      const exactMatch = TrendingVideo(
        id: '1',
        thumbnailUrl: '/uploads/photos/1.jpg',
        views: '0',
        viewCount: 0,
        title: 'Bokor Mountain Trip',
        caption: 'Our amazing Bokor Mountain Trip',
      );

      const highViewPartial = TrendingVideo(
        id: '2',
        thumbnailUrl: '/uploads/videos/2.jpg',
        views: '500K',
        viewCount: 500000,
        title: 'Cambodia Travel Vlog',
        caption: 'Visiting Bokor and other places',
      );

      int score(TrendingVideo v, String q) {
        int s = 0;
        final t = v.title.toLowerCase().trim();
        final c = v.caption.toLowerCase().trim();
        if (t == q) s += 1000;
        else if (t.startsWith(q)) s += 800;
        else if (t.contains(q)) s += 600;

        if (c == q) s += 500;
        else if (c.startsWith(q)) s += 400;
        else if (c.contains(q)) s += 300;
        return s;
      }

      final query = 'bokor mountain trip';
      final scoreExact = score(exactMatch, query);
      final scorePartial = score(highViewPartial, query);

      expect(scoreExact, greaterThan(scorePartial));
      expect(scoreExact >= 1000, isTrue);

      final list = [highViewPartial, exactMatch];
      list.sort((a, b) {
        final sa = score(a, query);
        final sb = score(b, query);
        if (sb != sa) return sb.compareTo(sa);
        return b.viewCount.compareTo(a.viewCount);
      });

      // Exact match must be first (#1) despite having 0 views
      expect(list.first.id, '1');
      expect(list.last.id, '2');
    });
  });
}
