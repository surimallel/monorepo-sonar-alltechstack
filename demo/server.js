import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { slugify } from '../node/src/slugify.js';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const javaClasses = resolve(root, 'demo/.build/java');
const pythonCommand = process.platform === 'win32' ? 'python' : 'python3';

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: 'utf8',
    timeout: 10000,
    windowsHide: true,
  });
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(result.stderr.trim() || `${command} exited with status ${result.status}`);
  }
  return result.stdout.trim();
}

function compileJavaFeatures() {
  const sources = [
    'java-maven/src/main/java/com/example/monorepo/GreetingFormatter.java',
    'java-maven/src/main/java/com/example/monorepo/GreetingFormatterCli.java',
    'java-gradle/src/main/java/com/example/monorepo/TaxCalculator.java',
    'java-gradle/src/main/java/com/example/monorepo/TaxCalculatorCli.java',
  ];
  run('javac', ['-d', javaClasses, ...sources]);
}

try {
  compileJavaFeatures();
} catch (error) {
  console.error(`Unable to compile the Java demo features: ${error.message}`);
  process.exit(1);
}

async function readJson(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 16_384) {
      throw new Error('Request body is too large');
    }
  }
  return JSON.parse(body);
}

function send(response, status, contentType, body) {
  response.writeHead(status, { 'Content-Type': contentType, 'X-Content-Type-Options': 'nosniff' });
  response.end(body);
}

function sendJson(response, status, body) {
  send(response, status, 'application/json; charset=utf-8', JSON.stringify(body));
}

function requireString(value, field) {
  if (typeof value !== 'string') {
    throw new Error(`${field} must be a string`);
  }
  return value;
}

async function handleApi(request, response, pathname) {
  try {
    const body = await readJson(request);
    let result;
    switch (pathname) {
      case '/api/greeting':
        result = run('java', ['-cp', javaClasses, 'com.example.monorepo.GreetingFormatterCli', requireString(body.name, 'Name')]);
        break;
      case '/api/tax':
        result = run('java', [
          '-cp',
          javaClasses,
          'com.example.monorepo.TaxCalculatorCli',
          requireString(body.amount, 'Amount'),
          requireString(body.rate, 'Rate'),
        ]);
        break;
      case '/api/slug':
        result = slugify(requireString(body.value, 'Value'));
        break;
      case '/api/palindrome':
        result = run(pythonCommand, ['python/src/palindrome_cli.py', requireString(body.value, 'Value')]);
        break;
      default:
        sendJson(response, 404, { error: 'Not found' });
        return;
    }
    sendJson(response, 200, { result });
  } catch (error) {
    sendJson(response, 400, { error: error.message });
  }
}

const server = createServer(async (request, response) => {
  const pathname = new URL(request.url, 'http://127.0.0.1').pathname;
  if (request.method === 'POST' && pathname.startsWith('/api/')) {
    await handleApi(request, response, pathname);
    return;
  }
  if (request.method === 'GET' && (pathname === '/' || pathname === '/app.js')) {
    const file = pathname === '/' ? 'index.html' : 'app.js';
    const type = file.endsWith('.js') ? 'text/javascript; charset=utf-8' : 'text/html; charset=utf-8';
    try {
      send(response, 200, type, await readFile(new URL(file, import.meta.url)));
    } catch (error) {
      console.error(`Unable to serve ${file}: ${error.message}`);
      send(response, 500, 'text/plain; charset=utf-8', 'Unable to load demo page');
    }
    return;
  }
  sendJson(response, 404, { error: 'Not found' });
});

const port = Number(process.env.PORT || 3000);
server.listen(port, '127.0.0.1', () => {
  console.log(`All-tech-stack demo ready at http://127.0.0.1:${port}`);
});
