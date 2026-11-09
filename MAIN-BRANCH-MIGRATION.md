# master → main migration

The default branch was renamed from `master` to `main` on 2026-11-09.
Delete this file once every machine is up to date.

On each clone that still has `master`:

```sh
git switch main                # or: git branch -m master main
git pull
git fetch --prune              # drop the stale origin/master
git remote set-head origin -a  # point origin/HEAD at main
git branch -d master           # check `git log main..master` first if it refuses
```

- [x] ficdep
- [ ] teledep (on `main`; still needs the prune / set-head / delete steps)
