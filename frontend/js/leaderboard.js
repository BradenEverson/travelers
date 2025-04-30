fetch("/rankings", {
  method: "GET",
  headers: {
    "Content-Type": "application/x-www-form-urlencoded",
  },
})
  .then((response) => {
    if (!response.ok) {
      throw new Error("Network response was not ok");
    }
    return response.json();
  })
  .then((rankings) => {
    rankings.sort((a, b) => b.score - a.score);

    const leaderboardBody = document.getElementById("leaderboard-body");

    rankings.forEach((player, index) => {
      const row = document.createElement("tr");
      row.className = `border-b border-gray-700 ${index % 2 === 0 ? "bg-gray-800" : "bg-gray-750"}`;

      const rankCell = document.createElement("td");
      rankCell.className = "py-3 px-6 rank-cell";
      rankCell.textContent = index + 1;

      const nameCell = document.createElement("td");
      nameCell.className = "py-3 px-6";
      nameCell.textContent = player.name;

      const scoreCell = document.createElement("td");
      scoreCell.className = "py-3 px-6 text-right";
      scoreCell.textContent = player.score;

      row.appendChild(rankCell);
      row.appendChild(nameCell);
      row.appendChild(scoreCell);

      leaderboardBody.appendChild(row);
    });
  })
  .catch((error) => {
    console.error("Error:", error);
    const leaderboardBody = document.getElementById("leaderboard-body");
    leaderboardBody.innerHTML = `<tr class="border-b border-gray-700">
            <td colspan="3" class="py-3 px-6 text-center text-red-400">Error loading leaderboard: ${error.message}</td>
            </tr>`;
  });
