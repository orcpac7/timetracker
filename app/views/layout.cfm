<!--- Place HTML here that should be used as the default layout of your application. --->
<cfif application.contentOnly>
	<cfoutput>
		#flashMessages()#
		#includeContent()#
	</cfoutput>
<cfelse>
	<!DOCTYPE html>
	<html lang="en">
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<title>Time Tracker</title>
			<cfoutput>#csrfMetaTags()#</cfoutput>
			<link rel="stylesheet" href="/vendor/bootstrap/css/bootstrap.min.css">
			<link rel="stylesheet" href="/stylesheets/main.css">
		</head>

		<body>
			<nav class="navbar navbar-expand-lg navbar-dark bg-brand">
				<div class="container-fluid">
					<span class="navbar-brand mb-0 h1">Time Tracker</span>
					<button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarLinks" aria-controls="navbarLinks" aria-expanded="false" aria-label="Toggle navigation">
						<span class="navbar-toggler-icon"></span>
					</button>
					<div class="collapse navbar-collapse" id="navbarLinks">
						<ul class="navbar-nav">
							<cfoutput>
								<li class="nav-item">#linkTo(text="Time Tracker", route="timer", class="nav-link")#</li>
								<li class="nav-item">#linkTo(text="Project Codes", controller="projectCodes", action="index", class="nav-link")#</li>
								<li class="nav-item">#linkTo(text="Reports", route="dailyReport", class="nav-link")#</li>
							</cfoutput>
						</ul>
					</div>
				</div>
			</nav>
			<div class="container-fluid py-3">
				<cfoutput>
					#flashMessages()#
					#includeContent()#
				</cfoutput>
			</div>
			<script src="/vendor/bootstrap/js/bootstrap.bundle.min.js"></script>
		</body>
	</html>
</cfif>
