local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = ls.snippet
local i = ls.insert_node

ls.add_snippets("cpp", {
    s("cp", fmt([[
#include <bits/stdc++.h>
using namespace std;

#define fi first
#define se second
#define ll long long
#define mp make_pair
#define pb push_back
#define pii pair<int, int>
#define pll pair<long, long>
#define vi vector<int>
#define vll vector<long long>
#define sz(x) (x).size()
#define all(x) (x).begin(), (x).end()

const int maxN = 1e6+7;
const int oo = 1e9 + 7;
const ll loo = (ll)1e18 + 7;
const int MOD = 1e9 + 7;
const int N = 2e5 + 3;

void solve() {
    [1]
}

int main() {
    solve();
    return 0;
}
    ]], {
        i(1, "// coding section"),
    }, {
        delimiters = "[]"
    }))
})

ls.add_snippets("cpp", {
    s("code", fmt([[
#include <bits/stdc++.h>
using namespace std;
[1]

void solve() {
    [2]
}

int main() {
    solve();
    return 0;
}
    ]], {
        i(1, "// defining section"),
        i(2, "// coding section"),
    }, {
        delimiters = "[]"
    }))
})

