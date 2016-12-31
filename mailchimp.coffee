document.head.insertAdjacentHTML "beforeend","""
  <link href="https://cdn-images.mailchimp.com/embedcode/classic-10_7.css" rel="stylesheet" type="text/css">
  <style type="text/css">
  	#mc_embed_signup{background:#fff; clear:left; font:14px Helvetica,Arial,sans-serif; }
  </style>
"""

module.exports =
  show: ->
    div = document.createElement "div"

    div.innerHTML = """
      <div id="mc_embed_signup">
      <form action="//space.us14.list-manage.com/subscribe/post?u=8946c32e9db504ccc083d3fc7&amp;id=b8b708aea6" method="post" id="mc-embedded-subscribe-form" name="mc-embedded-subscribe-form" class="validate" target="_blank" novalidate>
          <div id="mc_embed_signup_scroll">
      	
      <div class="mc-field-group">
      	<label for="mce-EMAIL">Email Address </label>
      	<input type="email" value="" name="EMAIL" class="required email" id="mce-EMAIL">
      </div>
      	<div id="mce-responses" class="clear">
      		<div class="response" id="mce-error-response" style="display:none"></div>
      		<div class="response" id="mce-success-response" style="display:none"></div>
      	</div>    <!-- real people should not fill this in and expect good things - do not remove this or risk form bot signups-->
          <div style="position: absolute; left: -5000px;" aria-hidden="true"><input type="text" name="b_8946c32e9db504ccc083d3fc7_b8b708aea6" tabindex="-1" value=""></div>
          <div class="clear"><input type="submit" value="Subscribe" name="subscribe" id="mc-embedded-subscribe" class="button"></div>
          </div>
      </form>
      </div>
    """

    system.UI.Modal.show div
