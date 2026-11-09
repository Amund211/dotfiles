# master → main migration

The default branch was renamed from `master` to `main` on 2026-11-09.
Delete this file once every machine is up to date.

On each clone that still has `master`:

```sh
git fetch --prune              # get origin/main, drop the stale origin/master
git switch main
git pull
git remote set-head origin -a  # point origin/HEAD at main
git branch -d master           # check `git log main..master` first if it refuses
```

If you renamed with `git branch -m master main` instead of `git switch main`,
also run `git branch -u origin/main` (it still tracks `origin/master`), and skip
`git branch -d master`.

- [x] ficdep
- [x] teledep
- [x] miniluv
- [ ] minipax
- [x] miniplenty
- [ ] minitrue
- [ ] recdep
