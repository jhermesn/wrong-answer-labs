# Changelog

## [0.4.3](https://github.com/jhermesn/wrong-answer-labs/compare/v0.4.2...v0.4.3) (2026-11-05)


### Bug Fixes

* **rules:** accept an instance type set by a launch template in the stack ([#19](https://github.com/jhermesn/wrong-answer-labs/issues/19)) ([a232840](https://github.com/jhermesn/wrong-answer-labs/commit/a232840cba159eb25cadd1a3992059d8de8f328a))
* **skill:** guide graders away from checks the starting state passes ([#21](https://github.com/jhermesn/wrong-answer-labs/issues/21)) ([6209227](https://github.com/jhermesn/wrong-answer-labs/commit/6209227a39445190451e838e3449b5e7b36a0293))
* **skill:** reject reserved Lambda concurrency, which new accounts refuse ([#20](https://github.com/jhermesn/wrong-answer-labs/issues/20)) ([d801159](https://github.com/jhermesn/wrong-answer-labs/commit/d801159df069cd624968199f333161e1bc063326))
* **validate:** stop failing links that cannot be fetched ([#18](https://github.com/jhermesn/wrong-answer-labs/issues/18)) ([45dc3b4](https://github.com/jhermesn/wrong-answer-labs/commit/45dc3b47b3fa5ade73f735e23cdf2e5e74a04abe))

## [0.4.2](https://github.com/jhermesn/wrong-answer-labs/compare/v0.4.1...v0.4.2) (2026-10-19)


### Bug Fixes

* **rules:** keep rules from skipping when another resource lacks the property ([#16](https://github.com/jhermesn/wrong-answer-labs/issues/16)) ([ae4a9de](https://github.com/jhermesn/wrong-answer-labs/commit/ae4a9de379c69f2b5f849b7213b7473c44be36a1))

## [0.4.1](https://github.com/jhermesn/wrong-answer-labs/compare/v0.4.0...v0.4.1) (2026-10-18)


### Bug Fixes

* **skill:** attach the SSM policy in the template, not in a challenge ([#14](https://github.com/jhermesn/wrong-answer-labs/issues/14)) ([b2c58db](https://github.com/jhermesn/wrong-answer-labs/commit/b2c58dbafb9364e4a9aedcb49703862ffc74db11))

## [0.4.0](https://github.com/jhermesn/wrong-answer-labs/compare/v0.3.0...v0.4.0) (2026-10-18)


### Features

* **skill:** log validator and self-test runs as JSON lines ([7d192bc](https://github.com/jhermesn/wrong-answer-labs/commit/7d192bcdd37f3b4433155697224c703c00f4a6c4))


### Bug Fixes

* **skill:** match how --output text prints booleans and paginated queries ([31f43fe](https://github.com/jhermesn/wrong-answer-labs/commit/31f43fe0d318f1ef5f069af1ae55cf85eb1af50b))

## [0.3.0](https://github.com/jhermesn/wrong-answer-labs/compare/v0.2.2...v0.3.0) (2026-09-29)


### Features

* **skill:** use the AWS MCP Server for documentation lookups ([b864ea0](https://github.com/jhermesn/wrong-answer-labs/commit/b864ea0f38782e6b8e145517b626ed78c7b1ce40))

## [0.2.2](https://github.com/jhermesn/wrong-answer-labs/compare/v0.2.1...v0.2.2) (2026-09-27)


### Bug Fixes

* **skill:** recommend the self-test for every lab ([e1aa814](https://github.com/jhermesn/wrong-answer-labs/commit/e1aa81469d388142359dd29dd5cd0a5f8d1340e5))
