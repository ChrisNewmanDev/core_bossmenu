let currencySymbol = '$';
let allJobs = [];
let allLocations = [];
let aimedLocationCoords = null;
let aimModeOperation = null;
let moveLocationData = null;

window.addEventListener('message', function(event) {
    if (event.data.action === 'open') {
        openMenu(event.data.data);
    } else if (event.data.action === 'updateBalance') {
        document.getElementById('accountBalance').textContent = currencySymbol + formatNumber(event.data.balance || 0);
    } else if (event.data.action === 'close') {
        closeMenu();
    } else if (event.data.action === 'openAdmin') {
        openAdminMenu(event.data.jobs, event.data.locations);
    } else if (event.data.action === 'closeAdmin') {
        closeAdminMenu();
    } else if (event.data.action === 'updateAdminLocations') {
        updateAdminLocations(event.data.locations);
    } else if (event.data.action === 'confirmAimedLocation') {
        aimedLocationCoords = event.data.coords;
        if (aimModeOperation === 'place') {
            addNewLocation();
        } else if (aimModeOperation === 'move') {
            performMoveLocation();
        }
        aimModeOperation = null;
    } else if (event.data.action === 'hideAdminUI') {
        document.getElementById('adminmenu').style.opacity = '0';
    } else if (event.data.action === 'showAdminUI') {
        document.getElementById('adminmenu').style.opacity = '1';
    } else if (event.data.action === 'updateNearbyPlayers') {
        renderNearbyPlayers(event.data.players);
    }
});

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

document.getElementById('closeBtn').onclick = function() {
    closeMenu();
};

document.getElementById('depositBtn').onclick = function() {
    const amount = parseInt(document.getElementById('moneyAmount').value);
    if (amount > 0) {
        fetch(`https://${GetParentResourceName()}/bossAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: 'deposit', amount: amount })
        });
        document.getElementById('moneyAmount').value = '';
    }
};

document.getElementById('withdrawBtn').onclick = function() {
    const amount = parseInt(document.getElementById('moneyAmount').value);
    if (amount > 0) {
        fetch(`https://${GetParentResourceName()}/bossAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: 'withdraw', amount: amount })
        });
        document.getElementById('moneyAmount').value = '';
    }
};

function openMenu(data) {
    document.getElementById('bossmenu').classList.remove('hidden');
    document.getElementById('jobName').textContent = data.job.toUpperCase();
    document.getElementById('jobGrade').textContent = data.grade;
    currencySymbol = data.currency || '$';
    document.getElementById('accountBalance').textContent = currencySymbol + formatNumber(data.account || 0);
    
    const hireRange = data.hireRange || 5.0;
    document.getElementById('hireTitle').textContent = `👷 Hire Employee`;
    
    renderEmployees(data.employees, data.grades);
}

function closeMenu() {
    const menu = document.getElementById('bossmenu');
    if (!menu.classList.contains('hidden')) {
        menu.classList.add('hidden');
        fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
    }
}

function renderEmployees(employees, grades) {
    const tbody = document.querySelector('#employeeTable tbody');
    tbody.innerHTML = '';
    employees.forEach(emp => {
        const tr = document.createElement('tr');
        let gradeOptions = '<option value="" disabled selected>🔽 Select Rank</option>';
        if (grades && grades.length > 0) {
            grades.forEach(grade => {
                gradeOptions += `<option value="${grade.level}">${grade.level} - ${grade.name}</option>`;
            });
        }
        tr.innerHTML = `
            <td>${emp.name}</td>
            <td>${emp.grade}</td>
            <td class="employee-actions">
                <select class="grade-select" id="grade-${emp.citizenid}">
                    ${gradeOptions}
                </select>
                <button class="change-grade-btn" onclick="changeGrade('${emp.citizenid}')">🔄 Update</button>
                <button class="fire-btn" onclick="fireEmployee('${emp.citizenid}')">🗑️ Fire</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

function changeGrade(citizenid) {
    const gradeSelect = document.getElementById(`grade-${citizenid}`);
    const newGrade = parseInt(gradeSelect.value);
    if (newGrade >= 0 && !isNaN(newGrade)) {
        fetch(`https://${GetParentResourceName()}/bossAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: 'changeGrade', target: citizenid, grade: newGrade })
        });
        gradeSelect.value = '';
    }
}

function fireEmployee(citizenid) {
    fetch(`https://${GetParentResourceName()}/bossAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'fire', target: citizenid })
    });
}

function renderNearbyPlayers(players) {
    const nearbyList = document.getElementById('nearbyPlayersList');
    nearbyList.innerHTML = '';
    
    if (!players || players.length === 0) {
        nearbyList.innerHTML = '<p class="no-nearby">No players nearby</p>';
        return;
    }
    
    players.forEach(player => {
        const card = document.createElement('div');
        card.className = 'nearby-player-card';
        card.innerHTML = `
            <div class="nearby-player-info">
                <div class="nearby-player-name">${player.name}</div>
                <div class="nearby-player-id">ID: ${player.serverId}</div>
            </div>
            <button class="hire-btn" onclick="hirePlayer(${player.serverId}, '${player.name}')">✅ Hire</button>
        `;
        nearbyList.appendChild(card);
    });
}

function hirePlayer(serverId, playerName) {
    fetch(`https://${GetParentResourceName()}/bossAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'hire', target: serverId })
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeMenu();
        closeAdminMenu();
    }
});

let selectedJob = null;

function openAdminMenu(jobs, locations) {
    allJobs = jobs;
    allLocations = locations || [];
    document.getElementById('adminmenu').classList.remove('hidden');
    
    showJobListView();
    renderJobs(jobs);
    document.getElementById('jobSearch').value = '';
}

function closeAdminMenu() {
    const menu = document.getElementById('adminmenu');
    if (!menu.classList.contains('hidden')) {
        menu.classList.add('hidden');
        fetch(`https://${GetParentResourceName()}/closeAdmin`, { method: 'POST' });
    }
}

function showJobListView() {
    document.getElementById('jobListView').classList.remove('hidden');
    document.getElementById('jobDetailView').classList.add('hidden');
    selectedJob = null;
    
    renderJobs(allJobs);
}

function showJobDetailView(job) {
    selectedJob = job;
    document.getElementById('jobListView').classList.add('hidden');
    document.getElementById('jobDetailView').classList.remove('hidden');
    document.getElementById('selectedJobName').textContent = job.label || job.name;
    
    const jobLocations = allLocations.filter(loc => loc.job === job.name);
    renderJobLocations(jobLocations);
}

function updateAdminLocations(locations) {
    allLocations = locations || [];
    
    if (selectedJob && !document.getElementById('jobDetailView').classList.contains('hidden')) {
        const jobLocations = allLocations.filter(loc => loc.job === selectedJob.name);
        renderJobLocations(jobLocations);
    }
    
    if (!document.getElementById('jobListView').classList.contains('hidden')) {
        renderJobs(allJobs);
    }
}

function renderJobs(jobs) {
    const jobsList = document.getElementById('jobsList');
    jobsList.innerHTML = '';
    
    if (!jobs || jobs.length === 0) {
        jobsList.innerHTML = '<tr><td colspan="3" style="text-align: center; color: rgba(255,255,255,0.5); padding: 40px;">No jobs available</td></tr>';
        return;
    }
    
    jobs.forEach(job => {
        const hasLocations = allLocations.some(loc => loc.job === job.name);
        const locationCount = allLocations.filter(loc => loc.job === job.name).length;
        
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="job-name-cell">${job.name}</td>
            <td class="job-label-cell">${job.label || job.name}</td>
            <td class="job-status-cell">
                ${hasLocations 
                    ? `<span class="status-badge status-active">${locationCount} Location${locationCount !== 1 ? 's' : ''}</span>` 
                    : '<span class="status-badge status-none">No Locations</span>'}
            </td>
        `;
        tr.onclick = function() {
            showJobDetailView(job);
        };
        jobsList.appendChild(tr);
    });
}

function renderJobLocations(locations) {
    const locationsList = document.getElementById('detailLocationsList');
    locationsList.innerHTML = '';
    
    if (!locations || locations.length === 0) {
        locationsList.innerHTML = '<div class="empty-locations">No locations placed for this job yet.</div>';
        return;
    }
    
    locations.forEach(loc => {
        const locCard = document.createElement('div');
        locCard.className = 'location-card';
        locCard.innerHTML = `
            <div class="location-card-header">
                <div>
                    <div class="location-coords">📍 X: ${loc.coords.x.toFixed(1)} Y: ${loc.coords.y.toFixed(1)} Z: ${loc.coords.z.toFixed(1)}</div>
                    <div class="location-id">ID: ${loc.id}</div>
                </div>
            </div>
            <div class="location-card-actions">
                <button class="location-action-btn move-btn" onclick="moveLocation(${loc.id}, '${loc.job}')">📦 Move</button>
                <button class="location-action-btn remove-btn" onclick="removeLocation(${loc.id}, '${loc.job}')">🗑️ Remove</button>
                <button class="location-action-btn teleport-btn" onclick="teleportToLocation(${loc.coords.x}, ${loc.coords.y}, ${loc.coords.z})">🚀 Teleport</button>
            </div>
        `;
        locationsList.appendChild(locCard);
    });
}

function addNewLocation() {
    if (!selectedJob) return;
    
    fetch(`https://${GetParentResourceName()}/placeLocation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            job: selectedJob.name,
            coords: aimedLocationCoords
        })
    });
    
    aimedLocationCoords = null;
}

function performMoveLocation() {
    if (!moveLocationData) return;
    
    fetch(`https://${GetParentResourceName()}/moveLocation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            id: moveLocationData.id,
            job: moveLocationData.job,
            coords: aimedLocationCoords
        })
    });
    
    aimedLocationCoords = null;
    moveLocationData = null;
}

function toggleAimMode(operation) {
    aimModeOperation = operation;
    fetch(`https://${GetParentResourceName()}/toggleAimMode`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function moveLocation(locationId, jobName) {
    moveLocationData = { id: locationId, job: jobName };
    toggleAimMode('move');
}

function removeLocation(locationId, jobName) {
    fetch(`https://${GetParentResourceName()}/removeLocation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: locationId, job: jobName })
    });
}

function teleportToLocation(x, y, z) {
    fetch(`https://${GetParentResourceName()}/teleportToLocation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ coords: { x: x, y: y, z: z } })
    });
}

document.getElementById('jobSearch').addEventListener('input', function(e) {
    const searchTerm = e.target.value.toLowerCase();
    const filtered = allJobs.filter(job => 
        job.name.toLowerCase().includes(searchTerm) || 
        (job.label && job.label.toLowerCase().includes(searchTerm))
    );
    renderJobs(filtered);
});

document.getElementById('backBtn').addEventListener('click', function() {
    showJobListView();
});

document.getElementById('aimLocationBtn').addEventListener('click', function() {
    toggleAimMode('place');
});

document.getElementById('adminCloseBtn').onclick = function() {
    closeAdminMenu();
};
