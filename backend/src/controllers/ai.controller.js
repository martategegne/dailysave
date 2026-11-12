import { sendJson, sendError } from '../core/response.js';
import { aiAssistantService } from '../services/ai_assistant.service.js';

export const aiController = {
  /**
   * GET /api/v1/ai/consent
   */
  async getConsent(req, res) {
    const isConsentGiven = await aiAssistantService.getConsentStatus(req.user.id);
    sendJson(res, 200, { isConsentGiven });
  },

  /**
   * POST /api/v1/ai/consent
   */
  async setConsent(req, res) {
    const { consent } = req.body;
    if (typeof consent !== 'boolean') {
      return sendError(res, 400, 'Invalid request body. "consent" boolean is required.');
    }

    const updated = await aiAssistantService.setConsentStatus(req.user.id, consent);
    sendJson(res, 200, {
      message: consent ? 'AI financial insights enabled.' : 'AI financial insights disabled.',
      isConsentGiven: updated,
    });
  },

  /**
   * GET /api/v1/ai/insights
   */
  async getInsights(req, res) {
    const result = await aiAssistantService.generateInsights(req.user.id);

    if (result.consentRequired) {
      return sendError(res, 403, result.message, { consentRequired: true });
    }

    sendJson(res, 200, result);
  },
};
