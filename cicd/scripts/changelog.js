const https = require('https');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env file
const token = process.env.GITHUB_TOKEN;
const owner = process.env.GITHUB_OWNER; // The owner of the repository
const repo = process.env.GITHUB_REPO; // The repository name
const baseBranch = process.env.BASE_BRANCH; // The base branch
const currentBranch = process.env.CURRENT_BRANCH; // The current branch


var version = {
    major: process.env.MAJOR_VERSION || 0,
    minor: process.env.MINOR_VERSION || 1,
    patch: process.env.PATCH_VERSION || 0
}


// API base URL for the repository
const apiBaseUrl = `https://api.github.com/repos/${owner}/${repo}`;

function httpsGet(url, headers = {}) {
    return new Promise((resolve, reject) => {
        const options = {
            method: 'GET',
            headers: {
                'Authorization': `token ${token}`,
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'Node.js',
                ...headers,
            },
        };

        const req = https.request(url, options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(JSON.parse(data));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        req.end();
    });
}

// Function to compare two branches and get commits
async function compareBranches(baseBranch, currentBranch) {
    const url = `${apiBaseUrl}/compare/${baseBranch}...${currentBranch}`;
    try {
        const data = await httpsGet(url);
        return data; // Returns the comparison data (commits, files, etc.)
    } catch (error) {
        console.error(`Error comparing branches ${baseBranch} and ${currentBranch}:`, error.message);
        return null;
    }
}

// Function to get the files changed in a specific commit
async function getCommitFiles(commitSha) {
    const url = `${apiBaseUrl}/commits/${commitSha}`;
    try {
        const data = await httpsGet(url);
        return data.files; // Returns the list of files changed in the commit
    } catch (error) {
        console.error(`Error fetching files for commit ${commitSha}:`, error.message);
        return [];
    }
}
// Function to generate a changelog and collect stats from the comparison data
async function generateChangelog(baseBranch, currentBranch) {
    const comparisonData = await compareBranches(baseBranch, currentBranch);

    if (!comparisonData) {
        return;
    }

    const commits = comparisonData.commits;
    const filesChanged = new Set(); // To store unique file paths
    let totalPRs = 0;
    const changelog = [];
    const contributorStats = {};
    let firstChangeDate = null;
    let lastChangeDate = null;
    // inrease semVarLabel ++

    // Loop through commits to gather stats and changelog
    for (const commit of commits) {
        const commitSha = commit.sha;
        const commitMessage = commit.commit.message;
        const commitDate = new Date(commit.commit.committer.date);
        const commitUser = commit.committer.login; // The username of the person who made the commit
        const prNumber = extractPRNumberFromCommitMessage(commitMessage); // getSemVerLabel
        const semVerLabel = getSemVerLabel(commitMessage); // getSemVerLabel
        //console.log(semVerLabel)

        // Get files changed in the commit
        const commitFiles = await getCommitFiles(commitSha);
        commitFiles.forEach(file => filesChanged.add(file.filename));

        // Update first and last change dates
        if (!firstChangeDate || commitDate < firstChangeDate) {
            firstChangeDate = commitDate;
        }
        if (!lastChangeDate || commitDate > lastChangeDate) {
            lastChangeDate = commitDate;
        }

        // Add user contribution count
        if (!contributorStats[commitUser]) {
            contributorStats[commitUser] = {
                count: 0,
                commits: []
            };
        }
        contributorStats[commitUser].count += 1;
        contributorStats[commitUser].commits.push(commitSha);

        // Add to changelog
        if (!prNumber) {
            changelog.push({
                sha: commitSha,
                message: commitMessage,
                date: commitDate,
                user: commitUser,
                pr: prNumber ? `PR #${prNumber}` : null,
                label: semVerLabel
            });
        } 

        // Count PRs
        if (prNumber) {
            totalPRs++;
        } else {
            if (semVerLabel == "major") {
                version[semVerLabel] = version[semVerLabel]++;
                version["minor"] = 0;
                version["patch"] = 0;
            } else if (semVerLabel == "minor") {
                version[semVerLabel] = version[semVerLabel]++;
                version["patch"] = 0;
            } else {
                version[semVerLabel] = version[semVerLabel] + 1;
                //console.log(version[semVerLabel])
            }
        }
    }

    // Calculate time differences
    const timeSinceFirstChange = firstChangeDate ? (Date.now() - firstChangeDate.getTime()) : null;
    const timeSinceLastChange = lastChangeDate ? (Date.now() - lastChangeDate.getTime()) : null;

    // Prepare a list of unique users and their contribution counts
    const uniqueContributors = Object.keys(contributorStats).map(user => ({
        username: user,
        contributions: contributorStats[user].count
    }));

    // Export data to JSON file
    const result = {
        baseBranch,
        version,
        currentBranch,
        totalCommits: commits.length,
        totalPRs,
        totalFilesChanged: filesChanged.size,
        timeSinceFirstChange: timeSinceFirstChange ? `${Math.floor(timeSinceFirstChange / (1000 * 60 * 60 * 24))} days` : null,
        timeSinceLastChange: timeSinceLastChange ? `${Math.floor(timeSinceLastChange / (1000 * 60 * 60 * 24))} days` : null,
        totalContributors: uniqueContributors.length,
        uniqueContributors,
        changelog
    };

    var fileName = `changelog_${baseBranch}_to_${currentBranch}.json`;
    var filePath = path.join(__dirname, fileName);

    // Save the changelog and stats to a JSON file
    fs.writeFileSync(filePath, JSON.stringify(result, null, 2), 'utf-8');
    console.log(`Changelog and stats exported to ${fileName}`);


    fileName = `changelog.json`;
    filePath = path.join(__dirname, fileName);

    // Save the changelog and stats to a JSON file
    fs.writeFileSync(filePath, JSON.stringify(result, null, 2), 'utf-8');
    console.log(`Changelog and stats exported to ${fileName}`);
}

// Function to extract PR numbers from a commit message (e.g., "Merge pull request #XYZ")
function extractPRNumberFromCommitMessage(commitMessage) {
    const prRegex = /Merge pull request #(\d+)/;
    const match = commitMessage.match(prRegex);
    return match ? parseInt(match[1], 10) : null;
}

function getSemVerLabel(message) {
    const regex = /#(major|minor|patch)/ig;
    const matches = message.match(regex);

    if (matches) {
        const uniqueMatches = [...new Set(matches.map(match => match.toLowerCase()))];
        
        // If only one valid label is present, return it (without the '#').
        if (uniqueMatches.length === 1) {
            return uniqueMatches[0].replace('#', '');
        }
        
        // If there are multiple valid labels, take the last one.
        return uniqueMatches[uniqueMatches.length - 1].replace('#', '');
    }

    // Default to 'patch' if no valid labels are found.
    return 'patch';
}

// Main function
(async function main() {
    await generateChangelog(baseBranch, currentBranch);
})();
