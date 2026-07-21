const express = require('express');
const router = express.Router();

const runtime = require('../runtime');
const { Job } = require('../job');
const logger = require('logplease').create('api/v2');
const config = require('../config');

router.use((req, res, next) => {
    if (config.key && req.headers['authorization'] !== config.key) {
        return res.status(401).send({
            message: 'Unauthorized',
        });
    }

    next();
});

function parse_job(body) {
    const {
        language,
        version,
        args,
        stdin,
        files,
        compile_memory_limit,
        run_memory_limit,
        run_timeout,
        compile_timeout,
        run_cpu_time,
        compile_cpu_time,
    } = body;

    if (!language || typeof language !== 'string') {
        throw new Error('language is required as a string');
    }
    if (!version || typeof version !== 'string') {
        throw new Error('version is required as a string');
    }
    if (!files || !Array.isArray(files)) {
        throw new Error('files is required as an array');
    }
    for (const [i, file] of files.entries()) {
        if (typeof file.content !== 'string') {
            throw new Error(
                `files[${i}].content is required as a string`
            );
        }
    }

    const rt = runtime.get_latest_runtime_matching_language_version(
        language,
        version
    );
    if (rt === undefined) {
        throw new Error(`${language}-${version} runtime is unknown`);
    }

    if (
        rt.language !== 'file' &&
        !files.some(file => !file.encoding || file.encoding === 'utf8')
    ) {
        throw new Error('files must include at least one utf8 encoded file');
    }

    for (const constraint of ['memory_limit', 'timeout', 'cpu_time']) {
        for (const type of ['compile', 'run']) {
            const constraint_name = `${type}_${constraint}`;
            const constraint_value = body[constraint_name];
            const configured_limit = rt[`${constraint}s`][type];
            if (!constraint_value) {
                continue;
            }
            if (typeof constraint_value !== 'number') {
                throw new Error(
                    `If specified, ${constraint_name} must be a number`
                );
            }
            if (configured_limit <= 0) {
                continue;
            }
            if (constraint_value > configured_limit) {
                throw new Error(
                    `${constraint_name} cannot exceed the configured limit of ${configured_limit}`
                );
            }
            if (constraint_value < 0) {
                throw new Error(`${constraint_name} must be non-negative`);
            }
        }
    }

    return new Job({
        runtime: rt,
        args: args ?? [],
        stdin: stdin ?? '',
        files,
        timeouts: {
            run: run_timeout ?? rt.timeouts.run,
            compile: compile_timeout ?? rt.timeouts.compile,
        },
        cpu_times: {
            run: run_cpu_time ?? rt.cpu_times.run,
            compile: compile_cpu_time ?? rt.cpu_times.compile,
        },
        memory_limits: {
            run: run_memory_limit ?? rt.memory_limits.run,
            compile: compile_memory_limit ?? rt.memory_limits.compile,
        },
    });
}

router.use((req, res, next) => {
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
        return next();
    }

    if (!req.headers['content-type']?.startsWith('application/json')) {
        return res.status(415).send({
            message: 'requests must be of type application/json',
        });
    }

    next();
});

router.post('/execute', async (req, res) => {
    let job;
    try {
        job = parse_job(req.body);
    } catch (error) {
        return res.status(400).json({
            message: error instanceof Error ? error.message : 'Invalid request',
        });
    }
    let result;
    let executionError;
    try {
        const box = await job.prime();

        result = await job.execute(box);
        // Backward compatibility when the run stage is not started
        if (result.run === undefined) {
            result.run = result.compile;
        }
    } catch (error) {
        logger.error(`Error executing job: ${job.uuid}:\n${error}`);
        executionError = error;
    }

    try {
        await job.cleanup();
    } catch (error) {
        logger.error(`Error cleaning up job: ${job.uuid}:\n${error}`);
        return res.status(500).send({ message: 'Execution cleanup failed' });
    }

    return executionError
        ? res.status(500).send({ message: 'Execution failed' })
        : res.status(200).send(result);
});

router.get('/runtimes', (req, res) => {
    const runtimes = runtime.map(rt => {
        return {
            language: rt.language,
            version: rt.version.raw,
            aliases: rt.aliases,
            runtime: rt.runtime,
        };
    });

    return res.status(200).send(runtimes);
});

module.exports = router;
