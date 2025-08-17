# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KOEMO (コエモ) is a Japanese iOS random voice calling application currently in the specification/planning phase. The app connects users randomly for anonymous voice calls with gradual profile disclosure.

## Current Project State

This project has detailed specifications but **no code implementation yet**. To begin development, you'll need to:

1. Initialize an iOS Xcode project with Swift
2. Set up a backend service (recommended: Node.js with WebSocket support)
3. Integrate WebRTC for voice calling (consider NTT's SkyWay SDK)

## Key Architecture Components

Based on the specifications in `サービス説明.md`:

### Frontend (iOS)
- **Voice Calling**: WebRTC implementation, likely using SkyWay SDK
- **Background Support**: VoIP with CallKit/PushKit for background calls
- **UI Flow**: Simple one-tap calling with anonymous profiles that gradually reveal during calls

### Backend Services
- **Matching Service**: Real-time user pool management and random pairing
- **WebSocket Server**: For signaling and real-time events
- **REST API**: User profiles, chat history, ticket management
- **Database**: 24-hour ephemeral storage for chat/call history

### Core Features
- **Random Matching**: One-tap instant voice call connections
- **Anonymous Profiles**: Start with nicknames, reveal info gradually during calls
- **Ephemeral Design**: All history auto-deletes after 24 hours
- **Monetization**: Ads before calls or paid tickets to skip ads

## Development Commands

Since the project hasn't been initialized yet, here are the recommended setup commands:

### iOS Development
```bash
# Create new Xcode project
# File > New > Project > iOS App
# Product Name: KOEMO
# Interface: UIKit or SwiftUI
# Language: Swift

# Install CocoaPods dependencies (after creating Podfile)
pod install

# Open workspace
open KOEMO.xcworkspace
```

### Backend Development (Node.js)
```bash
# Initialize Node.js project
npm init -y

# Install core dependencies
npm install express ws mongodb dotenv
npm install --save-dev typescript @types/node nodemon

# Run development server
npm run dev
```

## API Endpoints Structure

Key endpoints to implement:
- `POST /api/register` - User registration
- `POST /api/call/request` - Start matching
- `WebSocket /signal` - WebRTC signaling
- `POST /api/call/cancel` - Cancel match
- `POST /api/call/end` - End call
- `GET /api/history` - Get 24hr call history
- `POST /api/messages` - Send message
- `POST /api/report` - Report user

## Security Considerations

- WebRTC provides end-to-end encryption for voice calls
- Implement 24/7 moderation system
- Add reporting features with screenshot capability
- Use device IDs for anonymous user tracking
- Age restriction (17+) in App Store settings