# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BBLearning** is an AI-powered math learning app for middle school students (grades 7-9), focused on personalized learning paths, intelligent practice recommendations, and AI-assisted tutoring. This is a personal project designed for a child's education.

**Related Project ID**: ai-proj #153

## Tech Stack

### Backend (Golang)
- **Framework**: Gin/Echo web framework
- **ORM**: GORM for database operations
- **Database**: PostgreSQL 15+ (main data store)
- **Cache**: Redis 7+ (caching layer)
- **Storage**: MinIO/S3 (file storage)
- **AI Integration**: OpenAI/Claude API for question generation, grading, and diagnosis
- **Authentication**: JWT tokens with bcrypt password hashing

### Frontend (React)
- **Framework**: React 18+ with TypeScript
- **State Management**: Zustand
- **Routing**: React Router v6
- **UI Library**: Ant Design
- **Build Tool**: Create React App (react-scripts)
- **Math Rendering**: KaTeX (planned)
- **API Client**: Axios with interceptors

### Mobile (Planned)
- **Framework**: React Native for iOS
- **Offline Support**: AsyncStorage for local caching
- **Sync Strategy**: Incremental delta sync with conflict resolution

## Project Structure

```
bblearning/
├── backend/                    # Golang backend
│   ├── cmd/server/            # Application entry point
│   ├── internal/
│   │   ├── api/               # HTTP handlers, middleware, routes
│   │   ├── service/           # Business logic (user, knowledge, practice, ai, analytics)
│   │   ├── repository/        # Data access layer (postgres, redis, minio)
│   │   ├── domain/            # Models, DTOs, enums
│   │   └── pkg/               # Internal utilities (auth, cache, logger, validator)
│   ├── config/                # Configuration files
│   ├── migrations/            # Database migration scripts
│   └── scripts/               # Utility scripts (seed data, etc.)
├── frontend/                  # React web app
│   ├── src/
│   │   ├── components/       # Reusable components
│   │   ├── pages/            # Page components (Dashboard, Knowledge, Practice, Review, Profile)
│   │   ├── hooks/            # Custom React hooks
│   │   ├── services/         # API service layer
│   │   ├── store/            # Zustand state management
│   │   ├── utils/            # Utility functions
│   │   └── types/            # TypeScript type definitions
│   └── public/               # Static assets
└── docs/                     # Documentation
    ├── architecture/         # Technical architecture, API specs
    ├── development/          # Task breakdown, development guide
    └── ui/                   # UI wireframes, interaction specs
```

## Key Architecture Concepts

### Backend Service Layer Pattern
The backend follows a clean architecture with clear separation of concerns:
- **API Layer** (`internal/api/`): HTTP handlers and routing
- **Service Layer** (`internal/service/`): Business logic and orchestration
- **Repository Layer** (`internal/repository/`): Data persistence abstraction
- **Domain Layer** (`internal/domain/`): Core business entities and types

### AI Service Integration
AI capabilities are centralized in `internal/service/ai/`:
- **Question Generation**: Uses LLM prompts to create personalized math problems
- **Smart Grading**: AI evaluates student answers with detailed feedback
- **Learning Diagnosis**: Analyzes practice records to identify weak points
- **Personalized Recommendations**: Suggests learning paths based on performance

### Frontend State Management
- Uses Zustand for global state (authentication, user data)
- API layer with Axios interceptors for automatic token refresh
- Planned: Protected routes with authentication guards

### Database Design
Core tables (see `docs/architecture/tech-architecture.md` section 3.4):
- `users`: User accounts with grade level
- `knowledge_points`: Hierarchical knowledge tree structure
- `questions`: Problem bank with JSONB content (supports LaTeX formulas)
- `practice_records`: Student answer history with AI feedback
- `learning_records`: Progress tracking per knowledge point
- `wrong_questions`: Error collection for targeted review
- `learning_statistics`: Daily aggregated metrics

## Common Development Commands

### Backend
```bash
# In backend/ directory
go mod download              # Install dependencies
go run cmd/server/main.go    # Run development server
go build -o bin/server cmd/server/main.go  # Build binary
go test ./...                # Run tests

# Using Makefile
make build                   # Build the application
make run                     # Run the server
make test                    # Run tests
make migrate-up              # Apply database migrations
make migrate-down            # Rollback migrations
make seed                    # Insert seed data
```

### Frontend
```bash
# In frontend/ directory
npm install                  # Install dependencies
npm start                    # Start development server (port 3000)
npm run build                # Production build
npm test                     # Run tests
```

### Docker Development Environment
```bash
# From project root
docker-compose up -d          # Start all services (postgres, redis, minio)
docker-compose down           # Stop all services
docker-compose logs -f        # View logs
docker-compose ps             # Check service status
```

### Database Migrations
```bash
# Create new migration
migrate create -ext sql -dir backend/migrations -seq migration_name

# Apply migrations
migrate -path backend/migrations -database "postgresql://user:pass@localhost:5432/bblearning_dev?sslmode=disable" up

# Rollback
migrate -path backend/migrations -database "postgresql://user:pass@localhost:5432/bblearning_dev?sslmode=disable" down 1
```

## API Structure

All APIs follow the `/api/v1/` versioning pattern. Key endpoints:

### Authentication (`/api/v1/auth/`)
- `POST /register` - User registration
- `POST /login` - User login (returns JWT tokens)
- `POST /refresh` - Refresh access token
- `POST /logout` - User logout

### Knowledge Points (`/api/v1/knowledge/`)
- `GET /tree?grade=7` - Get knowledge point hierarchy
- `GET /:id` - Get knowledge point details
- `PUT /:id/progress` - Update learning progress

### Practice (`/api/v1/practice/`)
- `POST /generate` - Generate practice questions
- `POST /submit` - Submit answers for grading
- `GET /history` - Get practice history
- `GET /wrong-questions` - Get wrong question collection

### AI Services (`/api/v1/ai/`)
- `POST /generate-question` - AI generates custom questions
- `POST /grade` - AI grades student answers
- `GET /diagnose` - Get learning weakness diagnosis
- `GET /recommend` - Get personalized recommendations

### Statistics (`/api/v1/statistics/`)
- `GET /learning` - Get learning statistics
- `GET /knowledge-mastery` - Get knowledge point mastery
- `GET /progress` - Get progress curve

See `docs/architecture/api-specification.md` for complete API documentation.

## Important Implementation Notes

### Authentication Flow
1. User logs in → receives `access_token` (expires in 1 hour) and `refresh_token`
2. Frontend stores tokens and includes `Authorization: Bearer {token}` header
3. API middleware validates JWT and extracts user ID
4. Use refresh token endpoint before access token expires

### AI Prompt Engineering
AI prompts are template-based in `internal/service/ai/prompts.go`:
- Use structured output (JSON format) for parsing
- Include grade level and difficulty in context
- For question generation: request LaTeX format for math formulas
- For grading: provide standard answer and student answer
- For diagnosis: include aggregate statistics and error patterns

### Math Formula Rendering
- Backend stores formulas in LaTeX format wrapped in `$...$` or `$$...$$`
- Frontend will use KaTeX for client-side rendering
- Questions stored in JSONB format support rich content (text, formulas, images)

### Caching Strategy
Redis caching keys follow pattern: `entity:identifier:attribute`
- User info: `user:{user_id}` (TTL: 30 min)
- Knowledge tree: `knowledge:tree:grade:{grade}` (TTL: 24 hours)
- Question details: `question:{question_id}` (TTL: 1 hour)
- User progress: `user:{user_id}:progress` (TTL: 10 min)

### Error Handling
Standard response format:
```json
{
  "code": 0,           // 0=success, 1000+=error
  "message": "...",    // Human-readable message
  "data": {},          // Response payload
  "request_id": "..."  // For tracing
}
```

Error codes:
- `1000`: Parameter error
- `1001`: Unauthorized
- `1002`: Token expired
- `2000`: Resource not found
- `3000`: Server error
- `4000`: External service error

## Development Workflow

### Git Branching
```
main (production)
  └── develop (development)
       ├── feature/feature-name
       ├── bugfix/bug-description
       └── hotfix/urgent-fix
```

### Commit Convention
Follow Conventional Commits:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation changes
- `refactor:` code refactoring
- `test:` test additions/changes
- `chore:` build/tooling changes

### Testing Requirements
- Backend unit tests: coverage > 80%
- Integration tests for critical flows
- Frontend: test user flows with React Testing Library

## Configuration Management

### Backend Configuration
Located in `backend/config/config.yaml`:
- Server settings (port, timeouts, mode)
- Database connection strings
- Redis configuration
- MinIO/S3 settings
- AI provider settings (API keys, model names)
- JWT secret and expiration

Use environment variables for sensitive data (API keys, passwords).

### Frontend Configuration
Environment variables in `.env`:
- `REACT_APP_API_URL`: Backend API base URL
- `REACT_APP_WS_URL`: WebSocket URL (for real-time features)

## Performance Considerations

### Backend
- Use database connection pooling (GORM default)
- Cache frequently accessed data (knowledge tree, user info)
- Use goroutines for concurrent operations
- Paginate large result sets (default: 20 items per page)
- Index frequently queried columns

### Frontend
- Code splitting with React.lazy()
- Virtualize long lists
- Debounce search inputs
- Use React.memo for expensive components
- Optimize image loading (lazy load, WebP format)

## Key Dependencies

### Backend
- `github.com/gin-gonic/gin` - Web framework
- `gorm.io/gorm` - ORM
- `github.com/golang-jwt/jwt/v5` - JWT authentication
- `github.com/go-redis/redis/v8` - Redis client
- `github.com/sashabaranov/go-openai` - OpenAI API client
- `github.com/robfig/cron/v3` - Scheduled tasks

### Frontend
- `react-router-dom` - Client-side routing
- `zustand` - State management
- `axios` - HTTP client
- `antd` - UI component library
- `katex` (planned) - Math formula rendering

## Deployment

### Development
Use Docker Compose to run all services locally:
- PostgreSQL on port 5432
- Redis on port 6379
- MinIO on ports 9000 (API) and 9001 (console)
- Backend on port 8080
- Frontend on port 3000

### Production
- Backend: Docker container on cloud server
- Frontend: Static files served by Nginx or deployed to Vercel
- Database: PostgreSQL with backup strategy
- SSL: Let's Encrypt certificates
- Monitoring: Application logs and metrics collection

### iOS App Distribution
- TestFlight for internal testing (family)
- Ad Hoc distribution via UDID registration
- Not intended for App Store release (personal use)

## Security Notes

- Passwords hashed with bcrypt (cost factor 10)
- JWT tokens include expiration and user claims
- Rate limiting on API endpoints (100 req/min for standard, 50 req/hour for AI)
- Input validation using `validator` package
- SQL injection prevention via parameterized queries
- XSS protection via proper escaping
- CORS configured for frontend origin

## Troubleshooting

### Backend won't start
- Check database connection: ensure PostgreSQL is running
- Verify Redis connection
- Check environment variables and config file
- Review logs in `backend/logs/`

### Frontend API calls fail
- Verify `REACT_APP_API_URL` points to correct backend
- Check CORS configuration in backend
- Inspect browser console for errors
- Verify JWT token is being sent in headers

### Migration errors
- Ensure database user has CREATE privilege
- Check migration file SQL syntax
- Verify migrations table exists
- Try rollback and re-apply

### AI API errors
- Check API key validity
- Monitor rate limits and quota
- Review prompt format and token usage
- Implement retry logic with exponential backoff

## External Resources

- PRD: See `PRD_初中数学AI学习APP.md` for product requirements
- Architecture: See `docs/architecture/tech-architecture.md`
- API Spec: See `docs/architecture/api-specification.md`
- Task Breakdown: See `docs/development/task-breakdown.md`

## Contact

This is a personal learning project. For questions or collaboration, refer to the repository README or project documentation.
- 不要在本地保存md文件。都用mcp保存到ai-proj任务文档中。本项目id：153