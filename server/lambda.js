const serverlessExpress = require('@vendia/serverless-express');
const express = require("express");
const { validateRequestOriginMiddleware } = require("./middlewares/validateRequestOriginMiddleware");
const { initWebchatController } = require("./controllers/initWebchatController");
const { refreshTokenController } = require("./controllers/refreshTokenController");
const { emailTranscriptController } = require("./controllers/emailTranscriptController");
const cors = require("cors");
const { allowedOrigins } = require("./helpers/getAllowedOrigins");

const app = express();

app.use(express.json());
app.use(
    cors({
        origins: allowedOrigins
    })
);

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post("/initWebchat", validateRequestOriginMiddleware, initWebchatController);
app.post("/refreshToken", validateRequestOriginMiddleware, refreshTokenController);
app.post("/email", validateRequestOriginMiddleware, emailTranscriptController);

// Export handler for Lambda
exports.handler = serverlessExpress({ app });
