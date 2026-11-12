import { URL } from 'node:url';
import { parseJsonBody } from './body-parser.js';
import { sendError } from './response.js';

export class Router {
  constructor() {
    this.routes = []; // { method, pattern, paramNames, handlers }
  }

  /**
   * Registers a route for a specific HTTP method and path pattern.
   * @param {string} method
   * @param {string} pathPattern e.g. '/api/v1/transactions/:id'
   * @param  {...Function} handlers
   */
  add(method, pathPattern, ...handlers) {
    const paramNames = [];
    const normalized = pathPattern.replace(/\/+$/, '') || '/';

    // Transform '/users/:id/details' into a RegExp with named capture groups
    const regexPattern = normalized.replace(/:([a-zA-Z0-9_]+)/g, (_, paramName) => {
      paramNames.push(paramName);
      return '([^/]+)';
    });

    const regex = new RegExp(`^${regexPattern}$`);

    this.routes.push({
      method: method.toUpperCase(),
      pattern: normalized,
      regex,
      paramNames,
      handlers,
    });
  }

  get(path, ...handlers) {
    this.add('GET', path, ...handlers);
  }

  post(path, ...handlers) {
    this.add('POST', path, ...handlers);
  }

  patch(path, ...handlers) {
    this.add('PATCH', path, ...handlers);
  }

  delete(path, ...handlers) {
    this.add('DELETE', path, ...handlers);
  }

  /**
   * Dispatches an incoming request against the route table.
   * @param {import('node:http').IncomingMessage} req
   * @param {import('node:http').ServerResponse} res
   */
  async handle(req, res) {
    try {
      const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
      const pathname = parsedUrl.pathname.replace(/\/+$/, '') || '/';
      const method = req.method.toUpperCase();

      // Parse query string parameters
      req.query = Object.fromEntries(parsedUrl.searchParams.entries());
      req.params = {};

      // Match route
      let matchedRoute = null;
      let matchedParams = {};

      for (const route of this.routes) {
        if (route.method !== method) continue;

        const match = pathname.match(route.regex);
        if (match) {
          matchedRoute = route;
          route.paramNames.forEach((name, index) => {
            matchedParams[name] = decodeURIComponent(match[index + 1]);
          });
          break;
        }
      }

      if (!matchedRoute) {
        return sendError(
          res,
          404,
          `Cannot ${method} ${pathname}. Route does not exist.`
        );
      }

      req.params = matchedParams;

      // Parse JSON request body if present
      req.body = await parseJsonBody(req);

      // Execute middleware and handler pipeline
      for (const handler of matchedRoute.handlers) {
        let isDone = false;
        await handler(req, res, () => {
          isDone = true;
        });

        // If the handler didn't call next(), but sent headers/closed the response, break
        if (res.writableEnded) break;
      }
    } catch (err) {
      if (err.name === 'BodyParserError' || err.name === 'ValidationError') {
        return sendError(res, err.statusCode || 400, err.message, err.errors || null);
      }

      console.error('[Unhandled Internal Error]:', err);
      sendError(res, 500, 'Internal Server Error', err.message);
    }
  }
}
