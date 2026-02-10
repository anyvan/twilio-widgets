const Twilio = require("twilio");
const { getSecrets } = require("./getSecrets");

let twilioClient;

const getTwilioClient = async () => {
    if (twilioClient) {
        return twilioClient;
    }

    const secrets = await getSecrets();

    const newClient = new Twilio(secrets.API_KEY, secrets.API_SECRET, {
        accountSid: secrets.ACCOUNT_SID,
        region: secrets.TWILIO_REGION
    });

    twilioClient = newClient;

    return newClient;
};

module.exports = { getTwilioClient };
