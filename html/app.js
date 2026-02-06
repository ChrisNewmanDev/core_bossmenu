window.addEventListener('message', function(event) {
    if (event.data.action === 'open') {
        openMenu(event.data.data);
    }
});

document.getElementById('closeBtn').onclick = function() {
    closeMenu();
};

document.getElementById('payBtn').onclick = function() {
    const amount = parseInt(document.getElementById('payAmount').value);
    const selected = document.querySelector('tr.selected');
    if (selected && amount > 0) {
        const citizenid = selected.dataset.citizenid;
        fetch(`https://${GetParentResourceName()}/bossAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: 'pay', target: citizenid, amount: amount })
        });
    }
};

function openMenu(data) {
    document.getElementById('bossmenu').classList.remove('hidden');
    document.getElementById('jobName').textContent = data.job;
    document.getElementById('jobGrade').textContent = data.grade;
    document.getElementById('accountBalance').textContent = data.account || 0;
    renderEmployees(data.employees);
}

function closeMenu() {
    document.getElementById('bossmenu').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
}

function renderEmployees(employees) {
    const tbody = document.querySelector('#employeeTable tbody');
    tbody.innerHTML = '';
    employees.forEach(emp => {
        const tr = document.createElement('tr');
        tr.dataset.citizenid = emp.citizenid;
        tr.onclick = function() {
            document.querySelectorAll('#employeeTable tr').forEach(row => row.classList.remove('selected'));
            tr.classList.add('selected');
        };
        tr.innerHTML = `<td>${emp.name}</td><td>${emp.grade}</td><td><button onclick="fireEmployee('${emp.citizenid}')">Fire</button></td>`;
        tbody.appendChild(tr);
    });
}

function fireEmployee(citizenid) {
    fetch(`https://${GetParentResourceName()}/bossAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'fire', target: citizenid })
    });
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeMenu();
});
