import { sendJson, sendError } from '../core/response.js';
import { syncRepository } from '../repositories/sync.repository.js';

export const syncController = {
  /**
   * POST /api/v1/sync/push
   * Pushes a batch of client mutations to the cloud database.
   */
  async push(req, res) {
    const { mutations } = req.body;

    if (!Array.isArray(mutations)) {
      return sendError(res, 400, 'Invalid request body. "mutations" must be an array.');
    }

    if (mutations.length === 0) {
      return sendJson(res, 200, {
        results: [],
        serverSyncTimestamp: new Date().toISOString(),
      });
    }

    const result = await syncRepository.processPushBatch(req.user.id, mutations);

    sendJson(res, 200, result);
  },

  /**
   * GET /api/v1/sync/pull?since=ISO_TIMESTAMP
   * Pulls all mutations that occurred after the given timestamp.
   */
  async pull(req, res) {
    const { since } = req.query;

    if (since && isNaN(new Date(since).getTime())) {
      return sendError(res, 400, 'Invalid "since" query parameter. Expected ISO date string.');
    }

    const result = await syncRepository.pullChanges(req.user.id, since);

    sendJson(res, 200, result);
  },
};
