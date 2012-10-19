class Server < Renee::Application
  setup do
   views_path "./views"
  end
  app do
    path '/specs.js' do
      respond! do
        headers({
          :"Cache-Control" => "must-revalidate",
          :Expires =>(Time.now - 2000).utc.rfc2822,
          :"Content-Type" => "text/javascript"
        })
        body `rake specsjs`
      end
    end
    path '/specs' do
      haml! :index, :layout => 'spec_layout.haml'
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
        body $app.compile_coffee
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