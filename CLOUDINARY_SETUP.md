# Cloudinary Image Upload Setup Guide

## Overview
This guide will help you set up Cloudinary image upload functionality for article banners in your CivicLense app.

## Prerequisites
- Cloudinary account (free tier available)
- Your Cloudinary cloud name: `dvsabcntc`
- Your Cloudinary API credentials

## Setup Steps

### 1. Get Your Cloudinary Credentials
1. Log in to your [Cloudinary Console](https://console.cloudinary.com/)
2. Go to your dashboard
3. Note down your:
   - **Cloud Name**: `dvsabcntc` (already provided)
   - **API Key**: Found in the dashboard
   - **API Secret**: Found in the dashboard

### 2. Create Upload Preset
1. In your Cloudinary console, go to **Settings** → **Upload**
2. Scroll down to **Upload presets**
3. Click **Add upload preset**
4. Configure the preset:
   - **Preset name**: `news_hub`
   - **Signing Mode**: `Unsigned` (for client-side uploads)
   - **Folder**: `news_hub`
   - **Transformation**: 
     - Width: 800px
     - Height: 400px
     - Crop: Fill
     - Quality: Auto
5. Save the preset

### 3. Update Cloudinary Service
Open `lib/services/cloudinary_image_service.dart` and update the following lines:

```dart
static const String _apiKey = 'YOUR_API_KEY'; // Replace with your actual API key
static const String _apiSecret = 'YOUR_API_SECRET'; // Replace with your actual API secret
static const String _uploadPreset = 'news_hub'; // This should match your preset name
```

### 4. Test the Implementation
1. Run your Flutter app
2. Go to **Publish Report** screen
3. Try uploading an image:
   - Tap "Tap to add banner image"
   - Select an image from your gallery
   - Tap "Upload to Cloudinary"
   - The image should appear in the preview

## Features Implemented

### ✅ Image Upload UI
- **Location**: Publish Report screen
- **Features**:
  - Tap to select image from gallery
  - Image preview before upload
  - Upload progress indicator
  - Remove image option
  - Recommended dimensions display (800x400px)

### ✅ Banner Display
- **News Feed**: Banner images display in article cards (200px height)
- **Article Detail**: Banner images display prominently (300px height)
- **Responsive**: Images scale properly on different screen sizes

### ✅ Cloudinary Integration
- **Service**: `CloudinaryImageService` handles all upload operations
- **Optimization**: Automatic image optimization and resizing
- **Storage**: Images stored in `news_hub` folder
- **URLs**: Optimized URLs for different display contexts

## File Structure
```
lib/
├── services/
│   └── cloudinary_image_service.dart    # Cloudinary upload service
├── models/
│   └── report.dart                      # Updated with bannerImageUrl field
├── screens/
│   ├── publish_report_screen.dart       # Image upload UI
│   ├── news_feed_screen.dart           # Banner display in feed
│   └── article_detail_screen.dart      # Banner display in detail
```

## Troubleshooting

### Common Issues

1. **Upload fails with "Invalid API key"**
   - Check your API key and secret in `cloudinary_image_service.dart`
   - Ensure the upload preset exists and is unsigned

2. **Images not displaying**
   - Check your internet connection
   - Verify the image URLs are being saved correctly
   - Check Cloudinary console for uploaded images

3. **Permission denied**
   - Ensure the upload preset is set to "Unsigned"
   - Check that the folder `news_hub` exists in Cloudinary

### Testing Checklist
- [ ] Image selection works
- [ ] Image upload completes successfully
- [ ] Banner displays in news feed
- [ ] Banner displays in article detail
- [ ] Image removal works
- [ ] Different image formats supported (JPG, PNG, WebP)

## Security Notes
- The current implementation uses unsigned uploads for simplicity
- For production, consider implementing server-side uploads for better security
- API secrets should never be exposed in client-side code

## Next Steps
1. Configure your Cloudinary credentials
2. Test the image upload functionality
3. Customize image transformations as needed
4. Consider implementing image compression for better performance

## Support
If you encounter any issues, check:
1. Cloudinary console for upload logs
2. Flutter console for error messages
3. Network connectivity
4. Image file size and format compatibility
