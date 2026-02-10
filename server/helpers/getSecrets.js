const AWS = require('aws-sdk');

let cachedSecrets = null;

/**
 * Retrieves secrets from AWS Secrets Manager or environment variables
 * Uses environment variables for local development and Secrets Manager for Lambda
 */
async function getSecrets() {
    // Return cached secrets if available
    if (cachedSecrets) {
        return cachedSecrets;
    }

    // Check if running in Lambda environment
    const isLambda = !!process.env.AWS_LAMBDA_FUNCTION_NAME;

    if (isLambda) {
        // Running in Lambda - fetch from Secrets Manager (single JSON secret)
        const secretsManager = new AWS.SecretsManager({
            region: process.env.AWS_REGION || 'eu-west-1'
        });

        try {
            const appSecretName = process.env.APP_SECRET_NAME;
            if (!appSecretName) {
                throw new Error('APP_SECRET_NAME environment variable is required');
            }

            const result = await secretsManager.getSecretValue({ SecretId: appSecretName }).promise();
            const raw = JSON.parse(result.SecretString);

            // JSON shape: { twilio: {...}, sendgrid: {...} }
            const twilioSecrets = raw.twilio || {};
            const sendgridSecrets = raw.sendgrid || {};

            cachedSecrets = {
                // Twilio secrets
                ACCOUNT_SID: twilioSecrets.ACCOUNT_SID || twilioSecrets.account_sid,
                API_KEY: twilioSecrets.API_KEY || twilioSecrets.api_key,
                API_SECRET: twilioSecrets.API_SECRET || twilioSecrets.api_secret,
                AUTH_TOKEN: twilioSecrets.AUTH_TOKEN || twilioSecrets.auth_token,
                ADDRESS_SID: twilioSecrets.ADDRESS_SID || twilioSecrets.address_sid,
                CONVERSATIONS_SERVICE_SID: twilioSecrets.CONVERSATIONS_SERVICE_SID || twilioSecrets.conversations_service_sid,
                TWILIO_REGION: twilioSecrets.TWILIO_REGION || twilioSecrets.region || 'stage-us1',

                // SendGrid secrets
                SENDGRID_API_KEY: sendgridSecrets.SENDGRID_API_KEY || sendgridSecrets.api_key,
                FROM_EMAIL: sendgridSecrets.FROM_EMAIL || sendgridSecrets.from_email
            };
        } catch (error) {
            console.error('Error fetching secrets from Secrets Manager:', error);
            throw error;
        }
    } else {
        // Running locally - use environment variables
        cachedSecrets = {
            ACCOUNT_SID: process.env.ACCOUNT_SID,
            API_KEY: process.env.API_KEY,
            API_SECRET: process.env.API_SECRET,
            AUTH_TOKEN: process.env.AUTH_TOKEN,
            ADDRESS_SID: process.env.ADDRESS_SID,
            CONVERSATIONS_SERVICE_SID: process.env.CONVERSATIONS_SERVICE_SID,
            TWILIO_REGION: process.env.TWILIO_REGION,
            SENDGRID_API_KEY: process.env.SENDGRID_API_KEY,
            FROM_EMAIL: process.env.FROM_EMAIL
        };
    }

    return cachedSecrets;
}

module.exports = { getSecrets };
