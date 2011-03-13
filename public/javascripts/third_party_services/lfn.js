//controlIdStr - Comma Separated String of all the control names to be considered
function ChangeState(controlIdStr)
{

	alert('test');
	var controlsIdArr = controlIdStr.split(',');
	
	//Variable to store the control values
	var controlValString = "";
	
	//Foreach control get its value (given by the user)
	for (var controlId in controlsIdArr)
	{
		var controlObj = document.getElementById(controlId);
		if(controlObj != null)
		{
			//add control value in - controlName$controlValue format
			controlValString += controlId+"$"+controlObj.value;
			
			//for multilple values use $$ as separator
			controlValString += "$$";
		}
	}
	
	//Get current page url
	var pageUrl = window.location.href.toString();
	
	//Check if any query string param is present or not
	var isQueryStringPresent = pageUrl.indexOf('?') > -1;
	
	//Create the redirection url
	var redirectUrl = pageUrl;
	if(isQueryStringPresent)
		redirectUrl += "&";	
	else	
		redirectUrl += "?";	
	
	redirectUrl += "controlInfo="+controlValString;
	
	//Redirect the page to the above url - this will actually reload the same current page but with the new query string params which will update the component
	window.location = redirectUrl;
}