function fetchList() {
	var xhr = new XMLHttpRequest();
	xhr.onreadystatechange = () => {
		if (xhr.readyState === XMLHttpRequest.DONE) {
			if (xhr.status == 200) {
				var response = JSON.parse(xhr.responseText).flat();
        // now populate the select
        var content = [];
        for (var i=0, ii=response.length; i < ii; i++) {
					var j = response[i];
					content.push(`<option value="${j}">${j}</option>`);
				}
        document.getElementById('cid').innerHTML = content.join('');
        setTimeout(function() {
					populate();
				}, 0);
			}
		}
	};
	xhr.open("GET", "/curr");
	xhr.send();
};

function populate() {
	// take the currency cid and fetch details then populate the form
	var cid = document.getElementById('cid').value;
	var xhr = new XMLHttpRequest();
	xhr.onreadystatechange = () => {
		if (xhr.readyState === XMLHttpRequest.DONE) {
			if (xhr.status == 200) {
				var resp = JSON.parse(xhr.responseText);
				document.getElementById('name').value  = resp['name'];
				document.getElementById('iso').value   = resp['iso'];
				document.getElementById('price').value = resp['price'];
			}
		}
	};
	xhr.open('GET', '/curr?cid='+cid);
	xhr.send();
}

function saveDetails() {
	var record = {};
	var cid = document.getElementById('cid').value;
	record['cid'] = cid;
	record['name'] = document.getElementById('name').value;
	record['iso'] = document.getElementById('iso').value;
	record['price'] = document.getElementById('price').value;
	var payload = JSON.stringify(record);
	var xhr = new XMLHttpRequest();
	// omit error handling for brevity
	xhr.open('POST', '/curr?cid='+cid);
	xhr.send(payload);
};
