
# Terrerov Personal Website

🌐 **Live Site**: [www.terrerov.com](https://www.terrerov.com)

A high-performance, modern personal website built for GitHub Pages with advanced optimizations and PWA capabilities.

## ✨ Features

### 🚀 Performance Optimizations
- **Service Worker** for aggressive caching and offline support
- **Lazy loading** with Intersection Observer API
- **Debounced event handlers** for smooth interactions
- **Critical CSS inlining** for faster initial render
- **Preload/Prefetch** strategies for external resources
- **GPU-accelerated animations** with CSS transforms

### 📱 Progressive Web App (PWA)
- **Installable** on mobile and desktop devices
- **Offline functionality** with cached resources
- **App shortcuts** for quick navigation
- **Responsive design** optimized for all screen sizes

### 🎨 Modern Design
- **Animated sphere** with SVG graphics
- **GSAP animations** for smooth text effects
- **Modular CSS** with custom properties
- **Dark theme** optimized for readability

### 🔍 SEO Optimized
- **Structured meta tags** for social media
- **Sitemap.xml** for search engine indexing
- **Robots.txt** for crawler optimization
- **Open Graph** and **Twitter Cards** support

## 🏗️ Project Structure

```
src/
├── index.html          # Main HTML file
├── css/
│   └── style.css       # Unified, optimized CSS
├── js/
│   └── main.js         # Modular, performance-optimized JS
├── img/                # Image assets directory
├── sw.js               # Service Worker for caching
├── manifest.json       # PWA manifest
├── sitemap.xml         # SEO sitemap
├── robots.txt          # Search engine directives
├── CNAME               # Custom domain configuration
└── .nojekyll           # GitHub Pages optimization
```

## 🚀 Deployment

### Automatic Deployment (Recommended)
The site automatically deploys to GitHub Pages via GitHub Actions when you push to the main branch.

### Manual Deployment
1. Ensure your repository has GitHub Pages enabled
2. Set the source to "GitHub Actions"
3. Push your changes to the main branch
4. The workflow will automatically build and deploy

### Custom Domain Setup
1. Add your domain to the `CNAME` file
2. Configure your DNS provider:
   ```
   Type: CNAME
   Name: www
   Value: yourusername.github.io
   ```
3. Enable HTTPS in repository settings

## 🛠️ Development

### Local Development
```bash
# Start local server
cd src
python3 -m http.server 8000
# or
npx serve .
```

### Performance Testing
```bash
# Test with Lighthouse
npx lighthouse http://localhost:8000 --output html --output-path ./lighthouse-report.html

# Test PWA capabilities
npx pwa-asset-generator logo.svg ./img/icons --manifest ./manifest.json
```

## 📊 Performance Metrics

- **Lighthouse Score**: 95+ (Performance, Accessibility, Best Practices, SEO)
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Time to Interactive**: < 3.5s

## 🔧 Technologies Used

- **HTML5** with semantic markup
- **CSS3** with custom properties and modern features
- **Vanilla JavaScript** (ES6+) for optimal performance
- **GSAP** for smooth animations
- **Service Workers** for caching and offline support
- **GitHub Actions** for automated deployment
- **GitHub Pages** for hosting

## 📝 Configuration

### Environment Variables
No environment variables required - the site is fully static.

### External Dependencies
- GSAP (loaded via CDN with fallback)
- Google Fonts (preloaded for performance)
- GitHub API (for dynamic project loading)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Links

- **Website**: [www.terrerov.com](https://www.terrerov.com)
- **GitHub**: [github.com/terrerov](https://github.com/terrerov)
- **Repository**: [github.com/terrerov/surviving-chernarus](https://github.com/terrerov/surviving-chernarus)

---

**Built with ❤️ by Terrerov**
