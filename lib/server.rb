class Server < Renee::Application
  setup do
   views_path "./views"
  end
  app do
    path "/features" do
      respond! do
        headers({
          :"Cache-Control" => "must-revalidate",
          :Expires =>(Time.now - 2000).utc.rfc2822,
          :"Content-Type" => "text/pain"
        })
        body $app.compile_features
      end
    end
    path "/specs.js" do
      respond! do
        headers({
          :"Cache-Control" => "must-revalidate",
          :Expires =>(Time.now - 2000).utc.rfc2822,
          :"Content-Type" => "text/javascript"
        })
        body $app.compile_specs
      end
    end
    part "**" do
      remainder do |file|
        respond! do
          body File.read File.dirname(__FILE__)+"/../assets"+file
        end
      end
    end
    path "/cucumber" do
      html = $app.compile_haml
      html += "<script src='/**/cucumber.js' type='text/javascript'></script>"
      html += "<script src='/specs.js' type='text/javascript'></script>"
      respond! do
        headers({
          :"Content-Type" => "text/html"
        })
        body html
      end
    end
    path '/specs' do
      html = """
        <script>
        if (!Function.prototype.bind) {
          Function.prototype.bind = function (oThis) {
            if (typeof this !== 'function') {
              // closest thing possible to the ECMAScript 5 internal IsCallable function
              throw new TypeError('Function.prototype.bind - what is trying to be bound is not callable');
            }

            var aArgs = Array.prototype.slice.call(arguments, 1),
                fToBind = this,
                fNOP = function () {},
                fBound = function () {
                  return fToBind.apply(this instanceof fNOP && oThis
                                         ? this
                                         : oThis,
                                       aArgs.concat(Array.prototype.slice.call(arguments)));
                };

            fNOP.prototype = this.prototype;
            fBound.prototype = new fNOP();

            return fBound;
          };
        }
        </script>
      """
      html += $app.compile_haml
      html += """
        <link href='/**/jasmine.css' type='text/css' rel='stylesheet'/>
        <script src='/**/jasmine.js' type='text/javascript'></script>
        <script src='/**/jasmine-html.js' type='text/javascript'></script>
        <script src='/**/jasmine-console.js' type='text/javascript'></script>
        <script src='/specs.js' type='text/javascript'></script>
        <script>
          var console_reporter = new jasmine.ConsoleReporter()
          var jasmineEnv = jasmine.getEnv();
          var htmlReporter = new jasmine.HtmlReporter();
          jasmineEnv.addReporter(console_reporter);
          jasmineEnv.addReporter(htmlReporter);
          jasmineEnv.specFilter = function(spec) {
            return htmlReporter.specFilter(spec);
          };
          setTimeout(function(){
            jasmineEnv.execute();
          },2000)
        </script>
      """
      respond! do
        headers({
          :"Content-Type" => "text/html"
        })
        body html
      end
    end
    path "/style.css" do
      respond! do
        headers({
          :"Cache-Control" => "must-revalidate",
          :Expires =>(Time.now - 2000).utc.rfc2822,
          :"Content-Type" => "text/css"
        })
        body $app.compile_sass
      end
    end
    path "/index.js" do
      respond! do
        headers({
          :"Cache-Control" => "must-revalidate",
          :Expires =>(Time.now - 2000).utc.rfc2822,
          :"Content-Type" => "text/javascript"
        })
        body $app.compile_coffee /\.nw\./
      end
    end
    respond! do
      headers({
        :"Content-Type" => "text/html"
      })
      body $app.compile_haml
    end
  end
end