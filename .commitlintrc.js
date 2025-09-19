module.exports = {
    extends: ['@commitlint/config-conventional'],
    rules: {
        'type-enum': [
            2,
            'always',
            [
                'chore',
                'docs',
                'feat',
                'fix'
            ]
        ],
        'body-max-line-length': [0],
        'subject-case': [0]
    }
};
