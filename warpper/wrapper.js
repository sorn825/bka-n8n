const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const app = express();

app.use(express.json({ limit: '50mb' }));

const PORT = 3000;
const FLARESOLVERR_URL = 'http://localhost:8191/v1';

function stripHeavy($, $root) {
    $root.find('img, picture, source').remove();
    $root.find('svg').remove();
    $root.find('button, [role="button"]').remove();
    $root.find('script, style, noscript').remove();

    $root.find('*').each((_, node) => {
        const attrs = node.attribs || {};
        for (const name of Object.keys(attrs)) {
            const lname = name.toLowerCase();
            if (
                lname === 'style' ||
                lname === 'srcset' ||
                lname === 'sizes' ||
                lname.startsWith('data-') ||
                lname.startsWith('aria-')
            ) {
                $(node).removeAttr(name);
            }
        }
    });
}

app.post('/v1', async (req, res) => {
    try {
        const { selector, ...flaresolverrPayload } = req.body;

        const response = await axios.post(FLARESOLVERR_URL, flaresolverrPayload);

        if (!selector) {
            return res.json(response.data);
        }

        const fullHtml = response.data.solution.response;
        const $ = cheerio.load(fullHtml);

        const selectedData = [];

        $(selector).each((i, el) => {
            const $clone = $(el).clone();
            stripHeavy($, $clone);

            selectedData.push({
                html: $.html($clone)
            });
        });

        const newResponse = {
            ...response.data,
            solution: {
                ...response.data.solution,
                response: null,
                extracted_data: selectedData
            }
        };

        return res.json(newResponse);

    } catch (error) {
        console.error(error);
        return res.status(500).json({ error: 'Internal Wrapper Error' });
    }
});

app.listen(PORT, () => {
    console.log(`Wrapper running on port ${PORT}`);
});

