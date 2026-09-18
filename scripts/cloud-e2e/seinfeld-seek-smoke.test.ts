/**
 * Copied to obsidian-seek repo root by run-seinfeld-seek-smoke.sh for vitest (obsidian alias).
 */
import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { Scenario } from './src/test-harness/scenario';

const evalPath = process.env.SEINFELD_EVAL_JSON!;
const episodesDir = process.env.SEINFELD_EPISODES_DIR!;
const limit = Number(process.env.SEINFELD_SMOKE_LIMIT ?? '8');

type EvalFile = {
	examples: Array<{ query: string; expectedEpisode: string }>;
};

function loadEpisodes(dir: string): Map<string, string> {
	const map = new Map<string, string>();
	for (const name of fs.readdirSync(dir)) {
		if (!name.endsWith('.md')) continue;
		map.set(name, fs.readFileSync(path.join(dir, name), 'utf8'));
	}
	return map;
}

describe('Seinfeld trivia — Seek smoke', () => {
	it('rank-1 episode retrieval', async () => {
		const evalDoc = JSON.parse(fs.readFileSync(evalPath, 'utf8')) as EvalFile;
		const episodes = loadEpisodes(episodesDir);
		expect(episodes.size).toBeGreaterThan(0);

		const s = new Scenario();
		await s.boot();
		let t = 1000;
		for (const [file, body] of episodes) {
			s.vault.write(`Seinfeld/episodes/${file}`, body, t++);
		}
		await s.coldStart();

		const slice = evalDoc.examples.slice(0, Math.min(limit, evalDoc.examples.length));
		const hits: string[] = [];
		const misses: Array<{ query: string; expected: string; got: string | null }> = [];

		for (const ex of slice) {
			const { results } = await s.orch.search(ex.query, 5);
			const top = results[0]?.note_path ?? null;
			const ok =
				top != null &&
				(top.endsWith(ex.expectedEpisode) || top.includes(ex.expectedEpisode));
			if (ok) hits.push(ex.query);
			else misses.push({ query: ex.query, expected: ex.expectedEpisode, got: top });
		}

		console.log(JSON.stringify({ episodes: episodes.size, tested: slice.length, hits: hits.length, hitQueries: hits, misses }, null, 2));
		await s.teardown();
		expect(hits.length).toBeGreaterThan(0);
	});
});
